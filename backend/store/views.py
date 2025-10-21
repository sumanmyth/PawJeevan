# backend/store/views.py
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
import uuid

from .models import (
    Category, Brand, Product, Review,
    Cart, CartItem, Order, OrderItem, Wishlist
)
from .serializers import (
    CategorySerializer, BrandSerializer,
    ProductSerializer, ProductListSerializer, ReviewSerializer,
    CartSerializer, CartItemSerializer, OrderSerializer, WishlistSerializer
)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only categories
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    lookup_field = "slug"


class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only brands
    """
    queryset = Brand.objects.all()
    serializer_class = BrandSerializer
    lookup_field = "slug"


class ProductViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only products with filters/search/order
    """
    queryset = Product.objects.filter(is_active=True)
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["category", "brand", "pet_type", "is_featured"]
    search_fields = ["name", "description", "sku"]
    ordering_fields = ["price", "created_at", "name"]
    lookup_field = "slug"

    def get_serializer_class(self):
        if self.action == "list":
            return ProductListSerializer
        return ProductSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        min_price = self.request.query_params.get("min_price")
        max_price = self.request.query_params.get("max_price")
        if min_price:
            qs = qs.filter(price__gte=min_price)
        if max_price:
            qs = qs.filter(price__lte=max_price)
        return qs

    @action(detail=False, methods=["get"])
    def featured(self, request):
        """
        Return featured products
        """
        featured = self.get_queryset().filter(is_featured=True)[:10]
        ser = ProductListSerializer(featured, many=True, context={"request": request})
        return Response(ser.data)

    @action(detail=True, methods=["get"])
    def recommendations(self, request, slug=None):
        """
        Stub recommendations: products from same category
        """
        product = self.get_object()
        related = Product.objects.filter(
            category=product.category, is_active=True
        ).exclude(id=product.id)[:6]
        ser = ProductListSerializer(related, many=True, context={"request": request})
        return Response({
            "recommendations": ser.data,
            "message": "TODO: Implement AI-based personalized recommendations"
        })


class ReviewViewSet(viewsets.ModelViewSet):
    """
    CRUD for product reviews
    """
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ["product", "rating"]
    ordering_fields = ["created_at", "rating", "helpful_count"]

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"])
    def helpful(self, request, pk=None):
        review = self.get_object()
        review.helpful_count += 1
        review.save()
        return Response({"helpful_count": review.helpful_count})


class CartViewSet(viewsets.ViewSet):
    """
    Cart endpoints:
    - GET /api/store/cart/
    - POST /api/store/cart/add_item/
    - POST /api/store/cart/update_item/
    - POST /api/store/cart/remove_item/
    - POST /api/store/cart/clear/
    """
    permission_classes = [IsAuthenticated]

    def list(self, request):
        cart, _ = Cart.objects.get_or_create(user=request.user)
        ser = CartSerializer(cart, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def add_item(self, request):
        cart, _ = Cart.objects.get_or_create(user=request.user)
        product_id = request.data.get("product_id")
        quantity = int(request.data.get("quantity", 1))

        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=404)

        if product.stock < quantity:
            return Response({"error": f"Only {product.stock} items available"}, status=400)

        item, created = CartItem.objects.get_or_create(
            cart=cart, product=product, defaults={"quantity": quantity}
        )
        if not created:
            item.quantity += quantity
            if item.quantity > product.stock:
                return Response({"error": f"Cannot add more than {product.stock} items"}, status=400)
            item.save()

        ser = CartSerializer(cart, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def update_item(self, request):
        cart = Cart.objects.get(user=request.user)
        item_id = request.data.get("item_id")
        quantity = int(request.data.get("quantity", 1))

        if quantity < 1:
            return Response({"error": "Quantity must be at least 1"}, status=400)

        try:
            item = CartItem.objects.get(id=item_id, cart=cart)
        except CartItem.DoesNotExist:
            return Response({"error": "Cart item not found"}, status=404)

        if item.product.stock < quantity:
            return Response({"error": f"Only {item.product.stock} items available"}, status=400)

        item.quantity = quantity
        item.save()
        ser = CartSerializer(cart, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def remove_item(self, request):
        cart = Cart.objects.get(user=request.user)
        item_id = request.data.get("item_id")
        try:
            item = CartItem.objects.get(id=item_id, cart=cart)
            item.delete()
        except CartItem.DoesNotExist:
            return Response({"error": "Cart item not found"}, status=404)
        ser = CartSerializer(cart, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def clear(self, request):
        cart = Cart.objects.get(user=request.user)
        cart.items.all().delete()
        ser = CartSerializer(cart, context={"request": request})
        return Response(ser.data)


class OrderViewSet(viewsets.ModelViewSet):
    """
    Orders for the current user
    """
    queryset = Order.objects.all()  # helps DRF router infer basename (and browsable API)
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user).order_by("-created_at")

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx

    @transaction.atomic
    def create(self, request):
        cart = Cart.objects.get(user=request.user)
        if not cart.items.exists():
            return Response({"error": "Cart is empty"}, status=400)

        delivery_method = request.data.get("delivery_method", "shipping")
        shipping_address = request.data.get("shipping_address", "")
        shipping_city = request.data.get("shipping_city", "")
        shipping_state = request.data.get("shipping_state", "")
        shipping_zip = request.data.get("shipping_zip", "")
        shipping_phone = request.data.get("shipping_phone", "")
        payment_method = request.data.get("payment_method", "cod")

        subtotal = cart.total_price
        shipping_cost = float(request.data.get("shipping_cost", 0))
        tax = float(request.data.get("tax", 0))
        total = float(subtotal) + shipping_cost + tax

        order = Order.objects.create(
            user=request.user,
            order_number=f"ORD-{uuid.uuid4().hex[:8].upper()}",
            delivery_method=delivery_method,
            shipping_address=shipping_address,
            shipping_city=shipping_city,
            shipping_state=shipping_state,
            shipping_zip=shipping_zip,
            shipping_phone=shipping_phone,
            subtotal=subtotal,
            shipping_cost=shipping_cost,
            tax=tax,
            total=total,
            payment_method=payment_method,
        )

        for item in cart.items.select_related("product"):
            OrderItem.objects.create(
                order=order,
                product=item.product,
                product_name=item.product.name,
                product_price=item.product.discount_price or item.product.price,
                quantity=item.quantity,
            )
            # reduce stock
            item.product.stock -= item.quantity
            item.product.save()

        # clear cart
        cart.items.all().delete()

        ser = OrderSerializer(order, context={"request": request})
        return Response(ser.data, status=201)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        order = self.get_object()
        if order.status in ["shipped", "delivered"]:
            return Response({"error": "Cannot cancel shipped/delivered order"}, status=400)

        # restore stock
        for it in order.items.select_related("product"):
            if it.product:
                it.product.stock += it.quantity
                it.product.save()

        order.status = "cancelled"
        order.save()
        ser = OrderSerializer(order, context={"request": request})
        return Response(ser.data)


class WishlistViewSet(viewsets.ViewSet):
    """
    Wishlist endpoints:
    - GET /api/store/wishlist/
    - POST /api/store/wishlist/add/
    - POST /api/store/wishlist/remove/
    - POST /api/store/wishlist/toggle/
    """
    permission_classes = [IsAuthenticated]

    def list(self, request):
        wishlist, _ = Wishlist.objects.get_or_create(user=request.user)
        ser = WishlistSerializer(wishlist, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def add(self, request):
        wishlist, _ = Wishlist.objects.get_or_create(user=request.user)
        product_id = request.data.get("product_id")
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=404)

        wishlist.products.add(product)
        ser = WishlistSerializer(wishlist, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def remove(self, request):
        wishlist = Wishlist.objects.get(user=request.user)
        product_id = request.data.get("product_id")
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=404)

        wishlist.products.remove(product)
        ser = WishlistSerializer(wishlist, context={"request": request})
        return Response(ser.data)

    @action(detail=False, methods=["post"])
    def toggle(self, request):
        wishlist, _ = Wishlist.objects.get_or_create(user=request.user)
        product_id = request.data.get("product_id")
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=404)

        if wishlist.products.filter(id=product_id).exists():
            wishlist.products.remove(product)
            action = "removed"
        else:
            wishlist.products.add(product)
            action = "added"

        ser = WishlistSerializer(wishlist, context={"request": request})
        return Response({"action": action, "wishlist": ser.data})
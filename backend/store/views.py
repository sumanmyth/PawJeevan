# backend/store/views.py
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.exceptions import PermissionDenied
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
import uuid
from decimal import Decimal

from .models import (
    Category, Brand, Product, Review,
    Cart, CartItem, Order, OrderItem, Wishlist, AdoptionListing
)
from .serializers import (
    CategorySerializer, BrandSerializer,
    ProductSerializer, ProductListSerializer, ReviewSerializer,
    CartSerializer, CartItemSerializer, OrderSerializer, WishlistSerializer,
    AdoptionListingSerializer
)
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.utils.html import strip_tags
from django.template import defaultfilters
import logging

logger = logging.getLogger(__name__)


def send_order_confirmation_email(order, request=None):
    """Send a simple order confirmation email (plain + html) to order.billing_email.

    This is non-blocking (exceptions are caught and logged). Uses DEFAULT_FROM_EMAIL
    if available in settings, otherwise falls back to a sensible no-reply address.
    """
    try:
        to_email = (order.billing_email or "").strip()
        if not to_email:
            return

        # Prefer explicit OTP_FROM_EMAIL (allows 'Name <email>') then DEFAULT_FROM_EMAIL
        from_email = getattr(settings, "OTP_FROM_EMAIL", None) or getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@pawjeevan.local")
        # strip accidental surrounding quotes from env values like 'PawJeevan Support <no-reply@pawjeevan.com>'
        if isinstance(from_email, str):
            from_email = from_email.strip().strip('"\'')
        subject = f"Order Confirmation - {order.order_number}"

        # Build plain text and HTML body
        lines = []
        lines.append(f"Thank you for your order, {order.user.username}!")
        lines.append("")
        lines.append(f"Order number: {order.order_number}")
        lines.append("")
        lines.append("Items:")
        for it in order.items.all():
            name = it.product_name
            qty = it.quantity
            price = it.product_price
            lines.append(f" - {name} x{qty} @ {price} = {defaultfilters.floatformat(it.subtotal, 2)}")

        lines.append("")
        lines.append(f"Subtotal: {order.subtotal}")
        lines.append(f"Shipping: {order.shipping_cost}")
        lines.append(f"Tax: {order.tax}")
        lines.append(f"Total: {order.total}")
        lines.append("")
        lines.append("Shipping address:")
        lines.append(order.shipping_address or "-")
        lines.append("")
        lines.append("If you have any questions, reply to this email or contact support.")

        text_body = "\n".join(lines)

        # Basic HTML version
        html_lines = [f"<p>Thank you for your order, <strong>{order.user.username}</strong>!</p>",
                  f"<p><strong>Order number:</strong> {order.order_number}</p>",
                      "<h4>Items</h4>",
                      "<ul>"]
        for it in order.items.all():
            html_lines.append(f"<li>{it.product_name} &times; {it.quantity} — {defaultfilters.floatformat(it.subtotal, 2)}</li>")
        html_lines.extend([
            "</ul>",
            f"<p><strong>Subtotal:</strong> {order.subtotal}<br><strong>Shipping:</strong> {order.shipping_cost}<br><strong>Tax:</strong> {order.tax}<br><strong>Total:</strong> {order.total}</p>",
            f"<p><strong>Shipping address:</strong><br>{order.shipping_address or '-'} </p>",
            f"<p>If you have any questions, reply to this email or contact support.</p>",
        ])

        html_body = "\n".join(html_lines)

        msg = EmailMultiAlternatives(subject=subject, body=text_body, from_email=from_email, to=[to_email])
        msg.attach_alternative(html_body, "text/html")
        msg.send(fail_silently=False)
    except Exception as e:
        # Don't let email failures break order creation; log for later inspection
        logger.exception("Failed to send order confirmation email for order %s: %s", getattr(order, 'order_number', 'unknown'), str(e))


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
        # Support filtering by multiple categories via query params like
        # ?category__in=1,2,3 or by slug ?category__slug__in=food-and-treats,toys
        cat_in = self.request.query_params.get('category__in')
        if cat_in:
            try:
                ids = [int(x) for x in cat_in.split(',') if x.strip()]
                if ids:
                    qs = qs.filter(category__id__in=ids)
            except ValueError:
                pass

        cat_slug_in = self.request.query_params.get('category__slug__in')
        if cat_slug_in:
            slugs = [x.strip() for x in cat_slug_in.split(',') if x.strip()]
            if slugs:
                qs = qs.filter(category__slug__in=slugs)
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
        # Determine if this review should be marked as a verified purchase.
        # A review is verified if the requesting user has an order with status
        # 'delivered' that contains the product being reviewed.
        try:
            product = serializer.validated_data.get('product')
        except Exception:
            product = None

        is_verified = False
        try:
            if product is not None and self.request.user and self.request.user.is_authenticated:
                is_verified = Order.objects.filter(
                    user=self.request.user,
                    status__iexact='delivered',
                    items__product=product,
                ).exists()
        except Exception:
            # Don't let verification checks block review creation; default to False
            is_verified = False

        serializer.save(user=self.request.user, is_verified_purchase=is_verified)

    def perform_update(self, serializer):
        # Only the review owner may update
        obj = self.get_object()
        if obj.user != self.request.user:
            raise PermissionDenied("You do not have permission to edit this review")
        serializer.save()

    def perform_destroy(self, instance):
        # Only the review owner may delete
        if instance.user != self.request.user:
            raise PermissionDenied("You do not have permission to delete this review")
        instance.delete()

    @action(detail=True, methods=["post"])
    def helpful(self, request, pk=None):
        review = self.get_object()
        user = request.user
        # require authentication for voting
        if not user or not user.is_authenticated:
            return Response({"detail": "Authentication required"}, status=status.HTTP_401_UNAUTHORIZED)

        # Toggle user's helpful vote: if present remove, otherwise add
        if review.helpful_users.filter(id=user.id).exists():
            review.helpful_users.remove(user)
            review.helpful_count = review.helpful_users.count()
            review.save()
            return Response({"helpful_count": review.helpful_count, "marked": False})

        # Add user and update count
        review.helpful_users.add(user)
        # Keep helpful_count in sync with actual related set
        review.helpful_count = review.helpful_users.count()
        review.save()
        return Response({"helpful_count": review.helpful_count, "marked": True})


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

        # create or update cart item while snapshotting product data
        item, created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={
                "quantity": quantity,
                "product_name": product.name,
                "product_price": product.discount_price or product.price,
            },
        )
        if not created:
            item.quantity += quantity
            if item.quantity > product.stock:
                return Response({"error": f"Cannot add more than {product.stock} items"}, status=400)
            # ensure snapshot fields are present
            if not item.product_name:
                item.product_name = product.name
            if item.product_price is None:
                item.product_price = product.discount_price or product.price
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
        # ensure snapshot price and name remain in sync when updating
        if not item.product_name and item.product:
            item.product_name = item.product.name
        if item.product_price is None and item.product:
            item.product_price = item.product.discount_price or item.product.price
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
        # Support two flows:
        # 1) If the client sends an explicit 'items' list in the payload (Buy Now flow),
        #    create an order only for those items and DO NOT clear the user's server cart.
        # 2) Otherwise, create an order from the authenticated user's server cart (existing behavior).

        delivery_method = request.data.get("delivery_method", "shipping")
        shipping_address = request.data.get("shipping_address", "")
        shipping_city = request.data.get("shipping_city", "")
        shipping_state = request.data.get("shipping_state", "")
        shipping_zip = request.data.get("shipping_zip", "")
        shipping_phone = request.data.get("shipping_phone", "")
        payment_method = request.data.get("payment_method", "cod")

        shipping_cost = Decimal(str(request.data.get("shipping_cost", 0)))
        tax = Decimal(str(request.data.get("tax", 0)))

        items_payload = request.data.get("items")
        order = None

        if items_payload and isinstance(items_payload, list):
            # Build order from provided items
            subtotal = Decimal('0')
            line_items = []
            for it in items_payload:
                try:
                    pid = int(it.get('product_id'))
                except Exception:
                    return Response({"error": "Invalid product_id in items"}, status=400)

                qty = int(it.get('quantity', 1))
                price = Decimal(str(it.get('product_price', 0)))

                try:
                    prod = Product.objects.get(id=pid, is_active=True)
                except Product.DoesNotExist:
                    prod = None

                prod_name = prod.name if prod else it.get('product_name', '')
                prod_sku = prod.sku if prod else ''
                prod_meta = {
                    'category': prod.category.slug if prod and prod.category else None,
                    'brand': prod.brand.name if prod and prod.brand else None,
                }

                subtotal += price * qty
                line_items.append({'prod': prod, 'name': prod_name, 'sku': prod_sku, 'meta': prod_meta, 'price': price, 'qty': qty})

            total = subtotal + shipping_cost + tax

            # Prefer billing_email from payload, fallback to authenticated user's email
            billing_email = request.data.get('billing_email') or (getattr(request.user, 'email', '') if request.user else '')

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
                billing_email=billing_email,
            )

            for li in line_items:
                OrderItem.objects.create(
                    order=order,
                    product=li['prod'],
                    product_name=li['name'],
                    product_sku=li['sku'],
                    product_meta=li['meta'],
                    product_price=li['price'],
                    quantity=li['qty'],
                )
                # reduce stock on provided product if present
                if li['prod']:
                    # ensure we don't reduce below zero (double-check availability)
                    if li['prod'].stock is not None and li['prod'].stock < li['qty']:
                        # return an error which will abort the transaction
                        return Response({"error": f"Only {li['prod'].stock} items available for product {li['name']}"}, status=400)
                    li['prod'].stock -= li['qty']
                    if li['prod'].stock < 0:
                        li['prod'].stock = 0
                    li['prod'].save()

            ser = OrderSerializer(order, context={"request": request})
            # Send confirmation receipt to the user's billing email (best-effort)
            try:
                send_order_confirmation_email(order, request)
            except Exception:
                # helper already logs failures; swallow here to be safe
                pass
            return Response(ser.data, status=201)

        # Fallback: create from server-side cart
        cart = Cart.objects.get(user=request.user)
        if not cart.items.exists():
            return Response({"error": "Cart is empty"}, status=400)

        subtotal = cart.total_price
        total = Decimal(str(subtotal)) + shipping_cost + tax

        # Prefer billing_email from payload, fallback to authenticated user's email
        billing_email = request.data.get('billing_email') or (getattr(request.user, 'email', '') if request.user else '')

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
            billing_email=billing_email,
        )

        for item in cart.items.select_related("product"):
            prod = item.product
            prod_price = item.product_price if item.product_price is not None else (prod.discount_price or prod.price if prod else 0)
            prod_name = item.product_name or (prod.name if prod else '')
            prod_sku = prod.sku if prod else ''
            prod_meta = {
                'category': prod.category.slug if prod and prod.category else None,
                'brand': prod.brand.name if prod and prod.brand else None,
            }
            OrderItem.objects.create(
                order=order,
                product=prod,
                product_name=prod_name,
                product_sku=prod_sku,
                product_meta=prod_meta,
                product_price=prod_price,
                quantity=item.quantity,
            )
            # reduce stock (double-check availability)
            if prod:
                if prod.stock is not None and prod.stock < item.quantity:
                    return Response({"error": f"Only {prod.stock} items available for product {prod.name}"}, status=400)
                prod.stock -= item.quantity
                if prod.stock < 0:
                    prod.stock = 0
                prod.save()

        # clear cart
        cart.items.all().delete()

        ser = OrderSerializer(order, context={"request": request})
        # Send confirmation receipt to the user's billing email (best-effort)
        try:
            send_order_confirmation_email(order, request)
        except Exception:
            pass
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
    def add_pet(self, request):
        wishlist, _ = Wishlist.objects.get_or_create(user=request.user)
        pet_id = request.data.get("pet_id")
        try:
            pet = AdoptionListing.objects.get(id=pet_id)
        except AdoptionListing.DoesNotExist:
            return Response({"error": "Pet not found"}, status=404)

        wishlist.adoptions.add(pet)
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
    def remove_pet(self, request):
        wishlist = Wishlist.objects.get(user=request.user)
        pet_id = request.data.get("pet_id")
        try:
            pet = AdoptionListing.objects.get(id=pet_id)
        except AdoptionListing.DoesNotExist:
            return Response({"error": "Pet not found"}, status=404)

        wishlist.adoptions.remove(pet)
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

    @action(detail=False, methods=["post"])
    def toggle_pet(self, request):
        wishlist, _ = Wishlist.objects.get_or_create(user=request.user)
        pet_id = request.data.get("pet_id")
        try:
            pet = AdoptionListing.objects.get(id=pet_id)
        except AdoptionListing.DoesNotExist:
            return Response({"error": "Pet not found"}, status=404)

        if wishlist.adoptions.filter(id=pet_id).exists():
            wishlist.adoptions.remove(pet)
            action = "removed"
        else:
            wishlist.adoptions.add(pet)
            action = "added"

        ser = WishlistSerializer(wishlist, context={"request": request})
        return Response({"action": action, "wishlist": ser.data})


class AdoptionListingViewSet(viewsets.ModelViewSet):
    queryset = AdoptionListing.objects.all().order_by('-created_at')
    serializer_class = AdoptionListingSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['pet_type', 'location']  # Removed 'status' to handle it manually
    search_fields = ['title', 'pet_name', 'breed', 'description']

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def get_queryset(self):
        qs = super().get_queryset()
        
        # Only apply status filtering for list action
        # For detail actions (retrieve, update, destroy), return all objects
        if self.action != 'list':
            return qs
        
        status_param = self.request.query_params.get('status')
        
        # Handle 'all' status to show all pets regardless of status
        if status_param == 'all':
            # Don't filter by status, return all
            return qs
        elif status_param is None:
            # Default: show available and adoption-pending pets (for discover)
            qs = qs.filter(status__in=['available', 'pending'])
        else:
            # Filter by specific status if provided
            qs = qs.filter(status=status_param)
        
        return qs

    def perform_create(self, serializer):
        serializer.save(poster=self.request.user)
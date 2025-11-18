from rest_framework import serializers
from users.serializers import AbsoluteURLImageField  # reuse absolute URL field
from .models import (
    Category, Brand, Product, ProductImage, Review,
    Cart, CartItem, Order, OrderItem, Wishlist, AdoptionListing
)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = "__all__"


class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = "__all__"


class ProductImageSerializer(serializers.ModelSerializer):
    image = AbsoluteURLImageField()

    class Meta:
        model = ProductImage
        fields = ["id", "image", "is_primary", "alt_text"]


class ReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = Review
        fields = "__all__"
        read_only_fields = ["user", "is_verified_purchase", "helpful_count"]


class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)
    primary_image = serializers.SerializerMethodField()
    category_name = serializers.CharField(source="category.name", read_only=True)
    brand_name = serializers.CharField(source="brand.name", read_only=True)
    average_rating = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = "__all__"

    def get_primary_image(self, obj):
        request = self.context.get("request")
        primary = obj.images.filter(is_primary=True).first() or obj.images.first()
        if not primary:
            return None
        url = primary.image.url
        return request.build_absolute_uri(url) if request else url


class ProductListSerializer(serializers.ModelSerializer):
    primary_image = serializers.SerializerMethodField()
    average_rating = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = [
            "id", "name", "slug", "price", "discount_price",
            "primary_image", "stock", "is_active", "is_featured",
        ]

    def get_primary_image(self, obj):
        request = self.context.get("request")
        primary = obj.images.filter(is_primary=True).first() or obj.images.first()
        if not primary:
            return None
        url = primary.image.url
        return request.build_absolute_uri(url) if request else url


class CartItemSerializer(serializers.ModelSerializer):
    product = ProductListSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(),
        source="product",
        write_only=True
    )
    subtotal = serializers.ReadOnlyField()

    class Meta:
        model = CartItem
        fields = ["id", "product", "product_id", "quantity", "subtotal", "created_at"]


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total_price = serializers.ReadOnlyField()
    items_count = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ["id", "items", "total_price", "items_count", "created_at", "updated_at"]

    def get_items_count(self, obj):
        return obj.items.count()


class OrderItemSerializer(serializers.ModelSerializer):
    subtotal = serializers.ReadOnlyField()

    class Meta:
        model = OrderItem
        fields = "__all__"


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    user_email = serializers.CharField(source="user.email", read_only=True)

    class Meta:
        model = Order
        fields = "__all__"
        read_only_fields = ["user", "order_number", "created_at", "updated_at"]


class WishlistSerializer(serializers.ModelSerializer):
    products = ProductListSerializer(many=True, read_only=True)

    class Meta:
        model = Wishlist
        fields = "__all__"


class AdoptionListingSerializer(serializers.ModelSerializer):
    poster_username = serializers.CharField(source='poster.username', read_only=True)
    photo = AbsoluteURLImageField(required=False, allow_null=True)

    class Meta:
        model = AdoptionListing
        fields = '__all__'
        read_only_fields = ['poster', 'created_at', 'updated_at']
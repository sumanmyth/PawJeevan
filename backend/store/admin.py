"""
Admin interface for Store app
"""
from django.contrib import admin
from .models import (
    Category, Brand, Product, ProductImage, Review,
    Cart, CartItem, Order, OrderItem, Wishlist, AdoptionListing
)
from django.utils.html import format_html
from django.utils.html import conditional_escape


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = [f.name for f in Category._meta.fields]
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ['name']


@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = [f.name for f in Brand._meta.fields]
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ['name']


class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 1


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    # Replace the raw description field with a truncated version for list display
    _field_names = [f.name for f in Product._meta.fields]
    list_display = [('short_description' if n == 'description' else n) for n in _field_names]
    list_filter = ['category', 'brand', 'pet_type', 'is_active', 'is_featured']
    search_fields = ['name', 'sku']
    prepopulated_fields = {'slug': ('name',)}
    inlines = [ProductImageInline]

    def short_description(self, obj):
        if not obj.description:
            return ''
        full = str(obj.description)
        # truncate to a reasonable length to keep rows compact
        max_len = 120
        if len(full) <= max_len:
            esc = conditional_escape(full)
            return format_html('<span title="{}">{}</span>', esc, esc)

        truncated = full[:max_len].rsplit(' ', 1)[0] + '...'
        return format_html('<span title="{}">{}</span>', conditional_escape(full), conditional_escape(truncated))
    short_description.short_description = 'description'


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = [f.name for f in Review._meta.fields]
    list_filter = ['rating', 'is_verified_purchase']
    search_fields = ['product__name', 'user__username']


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['product', 'product_name', 'product_sku', 'product_price', 'quantity', 'subtotal', 'product_meta_display']
    fields = ['product', 'product_name', 'product_sku', 'product_price', 'quantity', 'subtotal', 'product_meta_display']

    def product_meta_display(self, obj):
        if not obj.product_meta:
            return ''
        try:
            import json
            pretty = json.dumps(obj.product_meta, indent=2)
            return format_html('<pre style="white-space:pre-wrap">{}</pre>', conditional_escape(pretty))
        except Exception:
            return str(obj.product_meta)
    product_meta_display.short_description = 'Product Meta'


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    # Show a compact set of important fields in the list view
    list_display = ['order_number', 'user', 'status', 'payment_status', 'total', 'created_at']
    list_filter = ['status', 'payment_status', 'delivery_method']
    search_fields = ['order_number', 'user__email', 'tracking_number']
    readonly_fields = ['order_number', 'created_at']
    inlines = [OrderItemInline]


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    # Show useful cart summary fields
    list_display = ['id', 'user', 'items_count_display', 'total_price_display', 'created_at', 'updated_at']
    search_fields = ['user__username', 'user__email']
    inlines = []

    def items_count_display(self, obj):
        try:
            return obj.items_count
        except Exception:
            return 0
    items_count_display.short_description = 'Items Count'

    def total_price_display(self, obj):
        try:
            return obj.total_price
        except Exception:
            return 0
    total_price_display.short_description = 'Total Price'


class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0
    fields = ['product', 'product_name', 'product_price', 'quantity', 'subtotal', 'created_at']
    readonly_fields = ['subtotal', 'created_at']

# Attach cart item inline to CartAdmin
CartAdmin.inlines = [CartItemInline]


@admin.register(Wishlist)
class WishlistAdmin(admin.ModelAdmin):
    list_display = [f.name for f in Wishlist._meta.fields] + ['products_count', 'adoptions_count']
    search_fields = ['user__username']
    filter_horizontal = ('products', 'adoptions')

    def products_count(self, obj):
        return obj.products.count()
    products_count.short_description = 'Products'

    def adoptions_count(self, obj):
        return obj.adoptions.count()
    adoptions_count.short_description = 'Pets'


@admin.register(AdoptionListing)
class AdoptionListingAdmin(admin.ModelAdmin):
    list_display = [f.name for f in AdoptionListing._meta.fields]
    list_filter = ['pet_type', 'status', 'created_at']
    search_fields = ['pet_name', 'breed', 'location']
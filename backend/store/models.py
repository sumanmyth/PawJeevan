"""
Store models: Category, Brand, Product, Review, Cart, Order, Wishlist
"""
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal
from users.models import User


class Category(models.Model):
    """Product categories"""
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    icon = models.ImageField(upload_to='categories/', blank=True, null=True)
    parent = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='subcategories'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'Categories'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Brand(models.Model):
    """Product brands"""
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(unique=True)
    logo = models.ImageField(upload_to='brands/', blank=True, null=True)
    description = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Product(models.Model):
    """Products in store"""
    PET_TYPE_CHOICES = [
        ('dog', 'Dog'),
        ('cat', 'Cat'),
        ('bird', 'Bird'),
        ('fish', 'Fish'),
        ('rabbit', 'Rabbit'),
        ('all', 'All Pets'),
    ]
    
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    description = models.TextField()
    category = models.ForeignKey(
        Category, 
        on_delete=models.SET_NULL, 
        null=True, 
        related_name='products'
    )
    brand = models.ForeignKey(
        Brand, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='products'
    )
    pet_type = models.CharField(max_length=20, choices=PET_TYPE_CHOICES)
    
    price = models.DecimalField(max_digits=10, decimal_places=2)
    discount_price = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        null=True, 
        blank=True
    )
    stock = models.IntegerField(default=0)
    sku = models.CharField(max_length=50, unique=True)
    
    weight = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        null=True, 
        blank=True, 
        help_text="Weight in kg"
    )
    dimensions = models.CharField(
        max_length=100, 
        blank=True, 
        help_text="L x W x H"
    )
    
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    # SEO
    meta_title = models.CharField(max_length=200, blank=True)
    meta_description = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.name
    
    @property
    def average_rating(self):
        """Calculate average rating from reviews"""
        reviews = self.reviews.all()
        if reviews:
            return sum([r.rating for r in reviews]) / len(reviews)
        return 0
    
    @property
    def final_price(self):
        """Return discount price if available, else regular price"""
        return self.discount_price if self.discount_price else self.price


class ProductImage(models.Model):
    """Product images"""
    product = models.ForeignKey(
        Product, 
        on_delete=models.CASCADE, 
        related_name='images'
    )
    image = models.ImageField(upload_to='products/')
    is_primary = models.BooleanField(default=False)
    alt_text = models.CharField(max_length=200, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-is_primary', 'created_at']
    
    def __str__(self):
        return f"Image for {self.product.name}"


class Review(models.Model):
    """Product reviews and ratings"""
    product = models.ForeignKey(
        Product, 
        on_delete=models.CASCADE, 
        related_name='reviews'
    )
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='reviews'
    )
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    title = models.CharField(max_length=200)
    comment = models.TextField()
    is_verified_purchase = models.BooleanField(default=False)
    
    helpful_count = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['product', 'user']
    
    def __str__(self):
        return f"Review by {self.user.username} for {self.product.name}"


class Cart(models.Model):
    """Shopping cart"""
    user = models.OneToOneField(
        User, 
        on_delete=models.CASCADE, 
        related_name='cart'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Cart for {self.user.username}"
    
    @property
    def total_price(self):
        """Calculate total cart price"""
        return sum(item.subtotal for item in self.items.all())
    
    @property
    def items_count(self):
        """Count total items in cart"""
        return sum(item.quantity for item in self.items.all())


class CartItem(models.Model):
    """Items in shopping cart"""
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    # Snapshot fields to keep record if product changes later
    product_name = models.CharField(max_length=200, blank=True)
    product_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    quantity = models.IntegerField(default=1, validators=[MinValueValidator(1)])
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['cart', 'product']
    
    def __str__(self):
        name = self.product_name or (self.product.name if self.product else 'Item')
        return f"{self.quantity}x {name}"
    
    @property
    def subtotal(self):
        """Calculate item subtotal"""
        # Guard against None values when rendering admin inlines or unsaved forms
        price = None
        if self.product_price is not None:
            price = self.product_price
        elif self.product is not None:
            try:
                price = self.product.final_price
            except Exception:
                price = Decimal('0')
        else:
            price = Decimal('0')

        qty = self.quantity or 0
        try:
            return price * qty
        except Exception:
            # Fallback to Decimal multiplication to avoid TypeErrors
            return Decimal(str(price or 0)) * Decimal(str(qty))


class Order(models.Model):
    """Customer orders"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('packed', 'Packed'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    ]
    
    DELIVERY_CHOICES = [
        ('shipping', 'Shipping'),
        ('pickup', 'Pickup'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]
    
    order_number = models.CharField(max_length=50, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    
    # Delivery information
    delivery_method = models.CharField(max_length=20, choices=DELIVERY_CHOICES)
    shipping_address = models.TextField()
    shipping_city = models.CharField(max_length=100)
    shipping_state = models.CharField(max_length=100)
    shipping_zip = models.CharField(max_length=20)
    shipping_phone = models.CharField(max_length=15)
    
    # Payment information
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    shipping_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    tax = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=10, decimal_places=2)

    # Optional fields
    coupon_code = models.CharField(max_length=50, blank=True)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    currency = models.CharField(max_length=10, default='NPR')

    payment_method = models.CharField(max_length=50, default='pending')
    payment_status = models.CharField(
        max_length=20, 
        choices=PAYMENT_STATUS_CHOICES, 
        default='pending'
    )
    transaction_id = models.CharField(max_length=100, blank=True)
    payment_gateway = models.CharField(max_length=100, blank=True)
    
    # Order status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Tracking
    tracking_number = models.CharField(max_length=100, blank=True)
    delivery_instructions = models.TextField(blank=True)
    billing_email = models.EmailField(blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    
    notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Order {self.order_number}"


class OrderItem(models.Model):
    """Items in an order"""
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True)
    product_name = models.CharField(max_length=200)
    product_sku = models.CharField(max_length=100, blank=True)
    product_meta = models.JSONField(null=True, blank=True)
    product_price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.IntegerField(validators=[MinValueValidator(1)])
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.quantity}x {self.product_name}"
    
    @property
    def subtotal(self):
        """Calculate item subtotal"""
        price = self.product_price if self.product_price is not None else Decimal('0')
        qty = self.quantity or 0
        try:
            return price * qty
        except Exception:
            return Decimal(str(price or 0)) * Decimal(str(qty))


class Wishlist(models.Model):
    """User wishlist/favorites"""
    user = models.OneToOneField(
        User, 
        on_delete=models.CASCADE, 
        related_name='wishlist'
    )
    products = models.ManyToManyField(
        Product, 
        related_name='wishlisted_by', 
        blank=True
    )
    adoptions = models.ManyToManyField(
        'AdoptionListing',
        related_name='wishlisted_by',
        blank=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Wishlist for {self.user.username}"


class AdoptionListing(models.Model):
    """
    Pet adoption listings
    Shelters or individuals can post pets for adoption
    """
    PET_TYPE_CHOICES = [
        ('dog', 'Dog'),
        ('cat', 'Cat'),
        ('bird', 'Bird'),
        ('fish', 'Fish'),
        ('rabbit', 'Rabbit'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('pending', 'Adoption Pending'),
        ('adopted', 'Adopted'),
        ('closed', 'Closed'),
    ]
    
    # Basic info
    title = models.CharField(max_length=200)
    pet_name = models.CharField(max_length=100)
    pet_type = models.CharField(max_length=20, choices=PET_TYPE_CHOICES)
    breed = models.CharField(max_length=100, blank=True)
    age = models.IntegerField(help_text="Age in months")
    gender = models.CharField(max_length=10, choices=[('male', 'Male'), ('female', 'Female')])
    
    # Details
    description = models.TextField()
    health_status = models.TextField()
    vaccination_status = models.TextField()
    is_neutered = models.BooleanField(default=False)
    
    # Media
    photo = models.ImageField(upload_to='adoption/', blank=True, null=True)
    
    # Contact
    poster = models.ForeignKey(User, on_delete=models.CASCADE, related_name='adoption_listings')
    contact_phone = models.CharField(max_length=15)
    contact_email = models.EmailField()
    location = models.CharField(max_length=200)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.pet_name} - {self.title}"
"""
Script to populate database with sample data
Run: python populate_db.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'pawjeevan_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import PetProfile, VaccinationRecord, MedicalRecord, Notification
from store.models import Category, Brand, Product, ProductImage, Review
from community.models import Post, Group, Event, AdoptionListing, LostFoundReport
from datetime import datetime, timedelta
from django.utils.text import slugify

User = get_user_model()

def create_users():
    """Create sample users"""
    print("Creating users...")
    
    users_data = [
        {'username': 'john_doe', 'email': 'john@example.com', 'first_name': 'John', 'last_name': 'Doe', 'password': 'pass123'},
        {'username': 'jane_smith', 'email': 'jane@example.com', 'first_name': 'Jane', 'last_name': 'Smith', 'password': 'pass123'},
        {'username': 'bob_wilson', 'email': 'bob@example.com', 'first_name': 'Bob', 'last_name': 'Wilson', 'password': 'pass123'},
        {'username': 'alice_brown', 'email': 'alice@example.com', 'first_name': 'Alice', 'last_name': 'Brown', 'password': 'pass123'},
    ]
    
    users = []
    for data in users_data:
        user, created = User.objects.get_or_create(
            username=data['username'],
            email=data['email'],
            defaults={
                'first_name': data['first_name'],
                'last_name': data['last_name'],
            }
        )
        if created:
            user.set_password(data['password'])
            user.save()
            print(f"  ✓ Created user: {user.username}")
        users.append(user)
    
    return users

def create_pets(users):
    """Create sample pet profiles"""
    print("\nCreating pet profiles...")
    
    pets_data = [
        {'owner': users[0], 'name': 'Max', 'pet_type': 'dog', 'breed': 'Golden Retriever', 'gender': 'male', 'weight': 30.5, 'color': 'Golden'},
        {'owner': users[0], 'name': 'Luna', 'pet_type': 'cat', 'breed': 'Persian', 'gender': 'female', 'weight': 4.2, 'color': 'White'},
        {'owner': users[1], 'name': 'Charlie', 'pet_type': 'dog', 'breed': 'Labrador', 'gender': 'male', 'weight': 28.0, 'color': 'Black'},
        {'owner': users[2], 'name': 'Bella', 'pet_type': 'cat', 'breed': 'Siamese', 'gender': 'female', 'weight': 3.8, 'color': 'Cream'},
        {'owner': users[3], 'name': 'Rocky', 'pet_type': 'dog', 'breed': 'German Shepherd', 'gender': 'male', 'weight': 35.0, 'color': 'Black & Tan'},
    ]
    
    pets = []
    for data in pets_data:
        pet, created = PetProfile.objects.get_or_create(
            owner=data['owner'],
            name=data['name'],
            defaults=data
        )
        if created:
            print(f"  ✓ Created pet: {pet.name} ({pet.pet_type})")
        pets.append(pet)
    
    return pets

def create_categories():
    """Create product categories"""
    print("\nCreating categories...")
    
    categories_data = [
        {'name': 'Dog Food', 'description': 'Premium food for dogs'},
        {'name': 'Cat Food', 'description': 'Nutritious food for cats'},
        {'name': 'Toys', 'description': 'Fun toys for pets'},
        {'name': 'Grooming', 'description': 'Grooming supplies and accessories'},
        {'name': 'Health & Wellness', 'description': 'Vitamins, supplements, and health products'},
        {'name': 'Accessories', 'description': 'Collars, leashes, and more'},
    ]
    
    categories = []
    for data in categories_data:
        category, created = Category.objects.get_or_create(
            name=data['name'],
            slug=slugify(data['name']),
            defaults={'description': data['description']}
        )
        if created:
            print(f"  ✓ Created category: {category.name}")
        categories.append(category)
    
    return categories

def create_brands():
    """Create product brands"""
    print("\nCreating brands...")
    
    brands_data = [
        {'name': 'Pedigree', 'description': 'Trusted dog food brand'},
        {'name': 'Whiskas', 'description': 'Popular cat food brand'},
        {'name': 'Royal Canin', 'description': 'Premium pet nutrition'},
        {'name': 'Purina', 'description': 'Quality pet food and treats'},
        {'name': 'PetSafe', 'description': 'Pet safety and training products'},
    ]
    
    brands = []
    for data in brands_data:
        brand, created = Brand.objects.get_or_create(
            name=data['name'],
            slug=slugify(data['name']),
            defaults={'description': data['description']}
        )
        if created:
            print(f"  ✓ Created brand: {brand.name}")
        brands.append(brand)
    
    return brands

def create_products(categories, brands):
    """Create sample products"""
    print("\nCreating products...")
    
    products_data = [
        {
            'name': 'Pedigree Adult Dry Dog Food',
            'category': categories[0],
            'brand': brands[0],
            'description': 'Complete and balanced nutrition for adult dogs',
            'price': 1299.00,
            'discount_price': 999.00,
            'stock': 50,
            'sku': 'DOG-FOOD-001',
            'pet_type': 'dog',
            'is_featured': True,
        },
        {
            'name': 'Whiskas Wet Cat Food - Tuna',
            'category': categories[1],
            'brand': brands[1],
            'description': 'Delicious tuna flavor wet food for cats',
            'price': 599.00,
            'stock': 100,
            'sku': 'CAT-FOOD-001',
            'pet_type': 'cat',
            'is_featured': True,
        },
        {
            'name': 'Royal Canin Puppy Food',
            'category': categories[0],
            'brand': brands[2],
            'description': 'Specially formulated for puppies',
            'price': 1599.00,
            'discount_price': 1399.00,
            'stock': 30,
            'sku': 'DOG-FOOD-002',
            'pet_type': 'dog',
            'is_featured': True,
        },
        {
            'name': 'Interactive Dog Toy Ball',
            'category': categories[2],
            'brand': brands[4],
            'description': 'Durable rubber ball for fetch and play',
            'price': 299.00,
            'stock': 75,
            'sku': 'TOY-001',
            'pet_type': 'dog',
        },
        {
            'name': 'Cat Scratching Post',
            'category': categories[2],
            'brand': brands[4],
            'description': 'Sisal scratching post to keep cats entertained',
            'price': 899.00,
            'discount_price': 699.00,
            'stock': 25,
            'sku': 'TOY-002',
            'pet_type': 'cat',
        },
        {
            'name': 'Pet Grooming Brush',
            'category': categories[3],
            'brand': brands[4],
            'description': 'Professional grooming brush for all pet types',
            'price': 399.00,
            'stock': 60,
            'sku': 'GROOM-001',
            'pet_type': 'all',
        },
        {
            'name': 'Dog Collar - Adjustable',
            'category': categories[5],
            'brand': brands[4],
            'description': 'Durable adjustable collar for dogs',
            'price': 249.00,
            'stock': 80,
            'sku': 'ACC-001',
            'pet_type': 'dog',
        },
        {
            'name': 'Cat Litter Box',
            'category': categories[5],
            'brand': brands[4],
            'description': 'Easy-to-clean litter box with cover',
            'price': 799.00,
            'stock': 40,
            'sku': 'ACC-002',
            'pet_type': 'cat',
        },
        {
            'name': 'Multivitamin Supplements for Dogs',
            'category': categories[4],
            'brand': brands[3],
            'description': 'Daily vitamins for healthy dogs',
            'price': 599.00,
            'stock': 50,
            'sku': 'HEALTH-001',
            'pet_type': 'dog',
        },
        {
            'name': 'Omega-3 Fish Oil for Cats',
            'category': categories[4],
            'brand': brands[3],
            'description': 'Supports healthy skin and coat',
            'price': 499.00,
            'stock': 45,
            'sku': 'HEALTH-002',
            'pet_type': 'cat',
        },
    ]
    
    products = []
    for data in products_data:
        product, created = Product.objects.get_or_create(
            sku=data['sku'],
            defaults={
                **data,
                'slug': slugify(data['name']),
                'meta_title': data['name'],
                'meta_description': data['description'][:150],
            }
        )
        if created:
            print(f"  ✓ Created product: {product.name}")
        products.append(product)
    
    return products

def create_reviews(products, users):
    """Create sample reviews"""
    print("\nCreating product reviews...")
    
    reviews_data = [
        {'product': products[0], 'user': users[0], 'rating': 5, 'title': 'Excellent food!', 'comment': 'My dog loves this food. Highly recommended!'},
        {'product': products[0], 'user': users[2], 'rating': 4, 'title': 'Good quality', 'comment': 'Good product but a bit expensive.'},
        {'product': products[1], 'user': users[1], 'rating': 5, 'title': 'Cats love it!', 'comment': 'My cat finishes it in minutes!'},
        {'product': products[2], 'user': users[3], 'rating': 5, 'title': 'Perfect for puppies', 'comment': 'Great nutrition for growing puppies.'},
        {'product': products[3], 'user': users[0], 'rating': 4, 'title': 'Durable toy', 'comment': 'Very durable, my dog plays with it daily.'},
    ]
    
    for data in reviews_data:
        review, created = Review.objects.get_or_create(
            product=data['product'],
            user=data['user'],
            defaults=data
        )
        if created:
            print(f"  ✓ Created review by {review.user.username} for {review.product.name}")

def create_posts(users):
    """Create sample community posts"""
    print("\nCreating community posts...")
    
    posts_data = [
        {'author': users[0], 'content': 'Just adopted a new puppy! So excited! 🐶'},
        {'author': users[1], 'content': 'My cat Luna turned 3 today! Happy birthday! 🎉🐱'},
        {'author': users[2], 'content': 'Looking for dog training tips. Any 
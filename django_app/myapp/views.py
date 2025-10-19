from django.shortcuts import render, redirect
from django.contrib import messages
from django.db import connection
from django.views.decorators.csrf import csrf_exempt
import psycopg2

def index(request):
    """Redirect to login page"""
    return redirect('login')

def login_view(request):
    """Handle login page and authentication"""
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT username FROM login WHERE username = %s AND password = %s",
                    [username, password]
                )
                user = cursor.fetchone()
                
                if user:
                    request.session['username'] = username
                    return redirect('home')
                else:
                    messages.error(request, 'Invalid credentials')
        except Exception as e:
            messages.error(request, f'Database error: {str(e)}')
    
    return render(request, 'login.html')

def register_view(request):
    """Handle user registration"""
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        try:
            with connection.cursor() as cursor:
                # Check if user already exists
                cursor.execute("SELECT username FROM login WHERE username = %s", [username])
                if cursor.fetchone():
                    messages.error(request, 'Username already exists')
                else:
                    cursor.execute(
                        "INSERT INTO login (username, password) VALUES (%s, %s)",
                        [username, password]
                    )
                    messages.success(request, 'Registration successful! Please login.')
                    return redirect('login')
        except Exception as e:
            messages.error(request, f'Registration error: {str(e)}')
    
    return render(request, 'register.html')

def home_view(request):
    """Home page - requires login"""
    if 'username' not in request.session:
        return redirect('login')
    
    username = request.session.get('username')
    return render(request, 'home.html', {'username': username})

def logout_view(request):
    """Handle logout"""
    request.session.flush()
    return redirect('login')
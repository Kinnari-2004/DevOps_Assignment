import sys
import time
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Configuration
APP_URL = "http://34.230.229.232:8000"  # Replace with actual manager IP
TEST_USERNAME = "ITA775"
TEST_PASSWORD = "2022PE0624"

def setup_driver():
    """Setup headless Firefox driver"""
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    
    driver = webdriver.Firefox(options=options)
    driver.implicitly_wait(10)
    return driver

def test_registration(driver):
    """Test user registration"""
    print("Test 1: Testing registration...")
    try:
        driver.get(f"{APP_URL}/register/")
        
        # Fill registration form
        username_field = driver.find_element(By.ID, "username")
        password_field = driver.find_element(By.ID, "password")
        
        username_field.send_keys(TEST_USERNAME)
        password_field.send_keys(TEST_PASSWORD)
        
        # Submit form
        driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
        
        # Wait for redirect or success message
        time.sleep(2)
        
        print("✓ Test 1 PASSED: Registration successful")
        return True
    except Exception as e:
        print(f"✗ Test 1 FAILED: {str(e)}")
        return False

def test_login(driver):
    """Test user login"""
    print("Test 2: Testing login...")
    try:
        driver.get(f"{APP_URL}/login/")
        
        # Fill login form
        username_field = driver.find_element(By.ID, "username")
        password_field = driver.find_element(By.ID, "password")
        
        username_field.send_keys(TEST_USERNAME)
        password_field.send_keys(TEST_PASSWORD)
        
        # Submit form
        driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
        
        # Wait for home page
        WebDriverWait(driver, 10).until(
            EC.url_contains("/home/")
        )
        
        print("✓ Test 2 PASSED: Login successful")
        return True
    except Exception as e:
        print(f"✗ Test 2 FAILED: {str(e)}")
        return False

def test_home_page(driver):
    """Test home page displays correct username"""
    print("Test 3: Testing home page...")
    try:
        # Check if username is displayed
        page_content = driver.page_source
        
        if TEST_USERNAME in page_content and "How are you" in page_content:
            print(f"✓ Test 3 PASSED: Home page displays 'Hello {TEST_USERNAME} How are you'")
            return True
        else:
            print("✗ Test 3 FAILED: Expected text not found on home page")
            return False
    except Exception as e:
        print(f"✗ Test 3 FAILED: {str(e)}")
        return False

def test_logout(driver):
    """Test logout functionality"""
    print("Test 4: Testing logout...")
    try:
        # Find and click logout button
        logout_btn = driver.find_element(By.LINK_TEXT, "Logout")
        logout_btn.click()
        
        # Wait for redirect to login page
        WebDriverWait(driver, 10).until(
            EC.url_contains("/login/")
        )
        
        print("✓ Test 4 PASSED: Logout successful")
        return True
    except Exception as e:
        print(f"✗ Test 4 FAILED: {str(e)}")
        return False

def test_protected_route(driver):
    """Test that home page is protected"""
    print("Test 5: Testing protected route...")
    try:
        # Try accessing home without login
        driver.get(f"{APP_URL}/home/")
        
        # Should redirect to login
        WebDriverWait(driver, 10).until(
            EC.url_contains("/login/")
        )
        
        print("✓ Test 5 PASSED: Protected route redirects to login")
        return True
    except Exception as e:
        print(f"✗ Test 5 FAILED: {str(e)}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("Starting Selenium Tests for DevOps Assignment")
    print("=" * 60)
    
    driver = None
    results = []
    
    try:
        driver = setup_driver()
        print(f"\nTesting application at: {APP_URL}\n")
        
        # Run tests
        results.append(test_registration(driver))
        results.append(test_login(driver))
        results.append(test_home_page(driver))
        results.append(test_logout(driver))
        results.append(test_protected_route(driver))
        
    except Exception as e:
        print(f"\n✗ Test suite failed with error: {str(e)}")
        sys.exit(1)
    finally:
        if driver:
            driver.quit()
    
    # Print summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Tests passed: {passed}/{total}")
    print("=" * 60)
    
    # Exit with appropriate code
    if passed == total:
        print("\n✓ All tests passed!")
        sys.exit(0)
    else:
        print(f"\n✗ {total - passed} test(s) failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()

import unittest
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

class AgriRentE2ETests(unittest.TestCase):
    def setUp(self):
        desired_caps = {
            "platformName": "Android",
            "deviceName": "Android Emulator",
            "app": "build/app/outputs/flutter-apk/app-debug.apk",
            "automationName": "UiAutomator2",
            "autoGrantPermissions": True
        }
        self.driver = webdriver.Remote("http://localhost:4723/wd/hub", desired_caps)
        self.wait = WebDriverWait(self.driver, 10)

    def test_a_to_z_flow(self):
        # 1. Login as Farmer
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Email Input"))).send_keys("farmer@agrirent.com")
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Password Input").send_keys("demo@1234")
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Login Button").click()
        time.sleep(3)

        # 2. Browse & Search Vehicles
        search_bar = self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Search Bar")))
        search_bar.send_keys("Tractor")
        
        # 3. Book Vehicle
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Vehicle Card"))).click()
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Book Now Button"))).click()
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Confirm Booking"))).click()
        time.sleep(2)

        # 4. Logout Farmer
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Profile Tab").click()
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Logout Button"))).click()
        time.sleep(2)

        # 5. Login as Owner
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Email Input"))).send_keys("owner@agrirent.com")
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Password Input").send_keys("demo@1234")
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Login Button").click()
        time.sleep(3)

        # 6. Approve Booking
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Bookings Tab").click()
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Approve Booking Button"))).click()
        time.sleep(2)

        # 7. Logout Owner
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Profile Tab").click()
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Logout Button"))).click()
        time.sleep(2)

        # 8. Login as Admin
        self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Email Input"))).send_keys("admin@agrirent.com")
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Password Input").send_keys("demo@1234")
        self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, "Login Button").click()
        time.sleep(3)

        # 9. Verify Admin Dashboard Stats
        stats_card = self.wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "Total Bookings Stat")))
        self.assertTrue(stats_card.is_displayed())

    def tearDown(self):
        self.driver.quit()

if __name__ == '__main__':
    unittest.main()

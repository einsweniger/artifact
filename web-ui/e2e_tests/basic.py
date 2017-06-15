
import time
import unittest

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def get_items(list_element):
    return sorted(p.text for p in list_element.find_elements_by_tag_name('li'))

class TestRead(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.get('http://127.0.0.1:4000')

    def test_req(self):
        ''' navigate to REQ and check that it is valid '''
        driver = self.driver
        # time.sleep(0.5)
        name = "REQ"
        elem = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, name)))
        elem = driver.find_element_by_id(name)
        elem.click()

        expected_parts = ["REQ-purpose", "REQ-layout"]
        expected_partof = []

        expected_parts = sorted(expected_parts)
        expected_partof = sorted(expected_partof)

        # make sure the header looks good
        elem = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "rd_ehead")))
        assert elem.text == name

        # make sure partof and parts are correct
        parts_list = driver.find_element_by_id("rd_parts_" + name)
        partof_list = driver.find_element_by_id("rd_partof_" + name)

        assert expected_parts == get_items(parts_list)
        assert expected_partof == get_items(partof_list)

        import ipdb; ipdb.set_trace()

    def tearDown(self):
        self.driver.quit()

# if __name__ == "__main__":
#     unittest.main()

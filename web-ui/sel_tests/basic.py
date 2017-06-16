from __future__ import print_function

import os
import time
import re
import unittest
import subprocess
import tempfile

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

LIST_VIEW = "list_view"
EDIT_VIEW = "edit_view"
GO_LIST = "list"
URL_PAT = re.compile("Listening on (\S+)")

TARGET_ART = os.environ['TARGET_BIN']

def get_items(list_element):
    return sorted(p.text for p in list_element.find_elements_by_tag_name('li'))

class TestRead(unittest.TestCase):
    def setUp(self):
        self.stdout = tempfile.NamedTemporaryFile("rb+")
        cmd = [
            TARGET_ART,
            "--work-tree", "web-ui/sel_tests/ex_proj",
            "serve"
        ]
        self.art = subprocess.Popen(cmd, bufsize=1, stdout=self.stdout)
        print("ran cmd: ", cmd)
        with open(self.stdout.name, "rb") as f:
            start = time.time()
            while True:
                time.sleep(0.2)
                f.seek(0)
                if self.art.poll() is not None:
                    raise Exception("art died: {}".format(f.read()))
                match = URL_PAT.search(f.read())
                if match:
                    self.url = match.group(1)
                    break

        self.driver = webdriver.Firefox()

    def test_req(self):
        ''' navigate to REQ and check that it is valid '''
        expected_parts = sorted(["REQ-purpose", "REQ-layout"])
        expected_partof = sorted([])

        driver = self.driver
        driver.get(self.url)
        name = "REQ"
        elem = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, name)))
        assert driver.find_element_by_id(LIST_VIEW), "we are in list view"
        elem.click()

        # make sure the header looks good
        elem = WebDriverWait(driver, 5).until(
            EC.presence_of_element_located((By.ID, "rd_ehead")))
        assert driver.find_element_by_id(EDIT_VIEW), "we are in edit view"
        assert elem.text == name

        rd_parts = "rd_parts_" + name
        rd_partof = "rd_partof_" + name

        # make sure partof and parts are correct
        parts_list = driver.find_element_by_id(rd_parts)
        assert expected_parts == get_items(parts_list)
        partof_list = driver.find_element_by_id(rd_partof)
        assert expected_partof == get_items(partof_list)

        driver.find_element_by_id(GO_LIST).click()
        assert WebDriverWait(driver, 5).until(
            EC.presence_of_element_located((By.ID, name)))

        # parts are open by default, partof isn't
        assert driver.find_element_by_id(rd_parts)
        with self.assertRaises(NoSuchElementException):
            driver.find_element_by_id(rd_partof)

        # open columns and assert
        parts_list = driver.find_element_by_id("rd_parts_" + name)
        assert expected_parts == get_items(parts_list)

        driver.find_element_by_id("select_col_partof").click()
        partof_list = WebDriverWait(driver, 1).until(
            EC.presence_of_element_located((By.ID, rd_partof)))
        assert expected_partof == get_items(partof_list)

        # now close columns and assert
        driver.find_element_by_id("select_col_parts").click()
        WebDriverWait(driver, 1).until(
            EC.invisibility_of_element_located((By.ID, rd_parts)))

        driver.find_element_by_id("select_col_partof").click()
        WebDriverWait(driver, 1).until(
            EC.invisibility_of_element_located((By.ID, rd_partof)))

    def tearDown(self):
        self.driver.quit()
        self.art.kill()

# if __name__ == "__main__":
#     unittest.main()

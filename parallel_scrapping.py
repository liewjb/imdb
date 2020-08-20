import time
import random
import pandas as pd
import csv
from concurrent.futures import ThreadPoolExecutor
from selenium import webdriver

import threading

csv_writer_lock = threading.Lock()

options = webdriver.ChromeOptions()
options.add_argument("--ignore-certificate-errors")
options.add_argument("--incognito")
options.add_argument("--headless")

options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")


# url = "https://www.imdb.com/title/tt7052634/reviews?ref_=tt_urv"


def get_reviews(url, id, start):
    driver = webdriver.Chrome(executable_path="chromedriver", chrome_options=options)
    driver.get(url)
    while True:
        try:
            driver.find_element_by_id("load-more-trigger").click()
            time.sleep(random.randint(1, 5))
        except Exception as e:
            print(e)
            break

    text = driver.find_elements_by_css_selector("div.text.show-more__control")
    ranking = driver.find_elements_by_css_selector(
        ".ipl-ratings-bar>span> :nth-child(2)"
    )
    reviews = [[id] + [text[i].text] + [ranking[i].text] for i in range(0, len(text))]
    print(id, len(reviews))
    with open("data/reviews/all_reviews" + str(start) + ".csv", mode="a") as f1:
        review_writer = csv.writer(f1, delimiter=",")
        for r in reviews:
            review_writer.writerow(r)
    return pd.DataFrame(reviews)


def set_up_threads(urls, start):
    """
    Create a thread pool and download specified urls
    """

    with ThreadPoolExecutor(max_workers=7) as executor:
        return executor.map(
            get_reviews, urls["URLS"], urls["imdbId"], start, timeout=60
        )


if __name__ == "__main__":
    # read and generate urls
    review_count = pd.read_csv("only4.csv")

    review_count["URLS"] = [
        "https://www.imdb.com/title/tt" + str(id).zfill(7) + "/reviews?ref_=tt_urv"
        for id in review_count["imdbId"]
    ]
    print(len(review_count))
    for start in range(3800, int(len(review_count) / 100) * 100, 100):
        print(start)
        set_up_threads(review_count[start : start + 100], [start] * 100)

from playwright.sync_api import sync_playwright
from concurrent.futures import ThreadPoolExecutor
import os
def save_mhtml(path:str, text:str):
    with open(path, mode='w', encoding='UTF-8',newline='\n') as file:
        file.write(text)

def main():
    # opening the file in read mode  
    my_file = open("url_list.txt", "r")
    data = my_file.read()
    item_list = data.split("\n")
    my_file.close()
    return item_list
def get_fname(str_url):
    len_url=len(str_url)
    str_1=str_url[len_url-41:]
    str_2=str_1[0:len(str_1)-5]
    return str_2

def download_page(str_url):
    fname=get_fname(str_url) + '.mhtml'
    if(os.path.exists(fname)):
        return
    else:
        print(fname)
    with sync_playwright() as playwright:
        browser=playwright.chromium.launch(headless=False)
        page=browser.new_page()
        page.goto(str_url,wait_until="domcontentloaded")
        page.wait_for_selector("a[class=exhibitor-name]")
        page.wait_for_selector("img")
        page.wait_for_timeout(3000)
        client=page.context.new_cdp_session(page)
        mhtml=client.send('Page.captureSnapshot')['data']
        save_mhtml(fname,mhtml)
        browser.close()        

if __name__ == '__main__':
    items=main()
    with ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(download_page , items)
    print("All Authors Info Downloaded Successfully")


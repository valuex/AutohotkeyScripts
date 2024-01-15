
import sqlite3

favicons_file='D:\\SoftX\\Chrome_GenBookmark\\Favicons'
dest_db="D:\\SoftX\\test.db"


conn1 = sqlite3.connect(favicons_file)
cursor1 = conn1.cursor()
conn2 = sqlite3.connect(dest_db)
cursor2 = conn2.cursor()

sql_cmd='select guid, bk_url from bookmarks'
cursor2.execute(sql_cmd)
values = cursor2.fetchall()
for i in range(len(values)):
    this_guid=values[i][0]
    this_url=values[i][1]
    is_file=this_url.startswith('file:///')
    is_chrome_setting=this_url.startswith('chrome://')
    is_bookmarklet=this_url.startswith('javascript:')
    if( is_file or is_chrome_setting or is_bookmarklet):
        print (values[i][0])
    else:
        # print(this_url)
        try:
            sql_cmd='select icon_id from icon_mapping where page_url like \'' + this_url +'%\'' 
            cursor1.execute(sql_cmd)
            record = cursor1.fetchone()
            icon_id = record[0]
        except: 
            print('can not get icon_id for:' + this_url)           
            continue  # can not get icon_id by url, skip the loop
        try:
            sql_cmd='select image_data from favicon_bitmaps where icon_id =' + str(icon_id)  + ' and width=32'
            cursor1.execute(sql_cmd)
        except:
            sql_cmd='select image_data from favicon_bitmaps where icon_id =' + str(icon_id)  + ' and width=16'
            cursor1.execute(sql_cmd)
        try:
            record = cursor1.fetchone()[0]
        except:
            print('no icon file for:' + str(icon_id) + '; url:' + this_url)
            continue
        sql_cmd='update bookmarks set bk_icon = ?  where guid = ?'
        update_tutle=(record, '\'' + this_guid + '\'')
        cursor2.execute(sql_cmd,update_tutle)

conn2.commit()
cursor1.close()
conn1.close()
# conn.commit()
cursor2.close()
conn2.close()

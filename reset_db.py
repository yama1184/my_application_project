import sqlite3

def reset_database():
    conn = sqlite3.connect('recipes.db')
    cursor = conn.cursor()

    try:
        with open('reset_recipes.sql', 'r', encoding='utf-8') as f:
            sql_script = f.read()
        
        cursor.executescript(sql_script)
        conn.commit()
        print("データベースのリセットが完了しました。")
    except FileNotFoundError:
        print("エラー: 'reset_recipes.sql' ファイルが見つかりません。")
    finally:
        conn.close()

if __name__ == '__main__':
    reset_database()
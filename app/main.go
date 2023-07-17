package main

import (
	"database/sql"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"net/http"
	"os"
)

type Record struct {
	ID    int    `json:"id"`
	Value string `json:"value"`
}

func main() {
	db, err := sql.Open("mysql", "user:password@tcp(localhost:3306)/dbname")
	if err != nil {
		panic(err)
	}
	defer func(db *sql.DB) {
		_ = db.Close()
	}(db)

	mc := memcache.New("localhost:11211")

	r := gin.Default()

	r.GET("/db", func(c *gin.Context) {
		var result Record
		// 3秒遅延させるロングランニングクエリの実行
		err := db.QueryRow("SELECT *, SLEEP(5) FROM table WHERE id = ?", 1).Scan(&result.ID, &result.Value)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, result)
	})

	r.GET("/cache", func(c *gin.Context) {
		// キャッシュから取得
		item, err := mc.Get("key")

		// キャッシュがない場合
		if err == memcache.ErrCacheMiss {
			var result Record
			// DBから取得
			err = db.QueryRow("SELECT * FROM table WHERE id = ?", 1).Scan(&result.ID, &result.Value)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			// キャッシュ登録
			item = &memcache.Item{
				Key:   "key",
				Value: []byte(fmt.Sprintf("%d:%s", result.ID, result.Value)),
			}
			if err := mc.Set(item); err != nil {
				_, _ = fmt.Fprintln(os.Stderr, "Error closing the database: ", err)
				return
			}
			c.JSON(http.StatusOK, result)
			return
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// キャッシュ結果をレスポンス用に加工する
		result := Record{}
		_, _ = fmt.Sscanf(string(item.Value), "%d:%s", &result.ID, &result.Value)
		c.JSON(http.StatusOK, result)
	})

	_ = r.Run(":8080")
}

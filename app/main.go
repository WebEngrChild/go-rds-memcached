package main

import (
	"database/sql"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/joho/godotenv"
	"net/http"
	"os"
)

type Customer struct {
	ID          int    `json:"id"`
	Value       string `json:"value"`
	SleepResult int    `json:"sleepResult"`
}

func main() {
	err := godotenv.Load()
	if err != nil {
		panic(err)
	}
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASS")
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbName := os.Getenv("DB_NAME")

	db, err := sql.Open("mysql", fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPass, dbHost, dbPort, dbName))
	if err != nil {
		panic(err)
	}
	defer func(db *sql.DB) {
		_ = db.Close()
	}(db)

	mc := memcache.New("localhost:11211")

	r := gin.Default()

	r.GET("/db/:id", func(c *gin.Context) {
		paramId := c.Param("id")
		var result Customer
		// 5秒遅延させるクエリの実行
		err := db.QueryRow("SELECT id, value, SLEEP(5) FROM customers WHERE id = ?", paramId).Scan(&result.ID, &result.Value, &result.SleepResult)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, result)
	})

	r.GET("/cache/:id", func(c *gin.Context) {
		paramId := c.Param("id")
		// キャッシュから取得
		item, err := mc.Get("key")

		// キャッシュがない場合
		if err == memcache.ErrCacheMiss {
			var result Customer
			// DBから取得
			err = db.QueryRow("SELECT id, value FROM customers WHERE id = ?", paramId).Scan(&result.ID, &result.Value)
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
		result := Customer{}
		_, _ = fmt.Sscanf(string(item.Value), "%d:%s", &result.ID, &result.Value)
		c.JSON(http.StatusOK, result)
	})

	_ = r.Run(":8080")
}

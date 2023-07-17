package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/bradfitz/gomemcache/memcache"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"net/http"
	"os"
)

type Customer struct {
	ID          int    `json:"id"`
	Value       string `json:"value"`
	SleepResult int    `json:"sleepResult"`
}

func main() {
	// 環境変数の呼び出し
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASS")
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbName := os.Getenv("DB_NAME")
	cacheHost := os.Getenv("CACHE_HOST")
	cachePort := os.Getenv("CACHE_PORT")

	// MySQLへ接続
	db, err := sql.Open("mysql", fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPass, dbHost, dbPort, dbName))
	if err != nil {
		panic(err)
	}
	defer func(db *sql.DB) {
		_ = db.Close()
	}(db)

	// Confirm the connection to the database
	if err = db.Ping(); err != nil {
		panic(err)
	}

	// Memcachedへ接続
	mc := memcache.New(fmt.Sprintf("%s:%s", cacheHost, cachePort))

	// Ginでルーティング
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
		item, err := mc.Get(paramId)
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
			resultBytes, err := json.Marshal(result)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			item = &memcache.Item{
				Key:   paramId,
				Value: resultBytes,
			}
			if err := mc.Set(item); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
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
		if err = json.Unmarshal(item.Value, &result); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, result)
	})

	_ = r.Run(":8080")
}

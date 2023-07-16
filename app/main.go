package main

import (
	"database/sql"
	"fmt"
	"net/http"

	"github.com/bradfitz/gomemcache/memcache"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
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
	defer db.Close()

	mc := memcache.New("localhost:11211")

	r := gin.Default()

	r.GET("/db", func(c *gin.Context) {
		var result Record
		// 3秒遅延させるロングランニングクエリの実行
		err := db.QueryRow("SELECT *, SLEEP(3) FROM table WHERE id = ?", 1).Scan(&result.ID, &result.Value)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, result)
	})

	r.GET("/cache", func(c *gin.Context) {
		item, err := mc.Get("key")
		if err == memcache.ErrCacheMiss {
			var result Record
			err = db.QueryRow("SELECT * FROM table WHERE id = ?", 1).Scan(&result.ID, &result.Value)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			item = &memcache.Item{
				Key:   "key",
				Value: []byte(fmt.Sprintf("%d:%s", result.ID, result.Value)),
			}
			mc.Set(item)
			c.JSON(http.StatusOK, result)
			return
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		result := Record{}
		fmt.Sscanf(string(item.Value), "%d:%s", &result.ID, &result.Value)
		c.JSON(http.StatusOK, result)
	})

	r.Run(":8080")
}

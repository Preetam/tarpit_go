package main

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

var (
	connection *sql.DB
	user       = "root"
	pwd        = "mysql"
	host       = "mysql"
	port       = "3306"
	dbname     = "DBPROD"
	tablename  = "product"
	usertable  = "user"
)

func getConnection() *sql.DB {
	if connection == nil {
		dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", user, pwd, host, port, dbname)
		var err error
		log.Println(dsn)
		connection, err = sql.Open("mysql", dsn)
		if err != nil {
			log.Print(err)
			return nil
		}
	}

	return connection
}

func dbExec(sql string) bool {
	log.Println(sql)
	connection = getConnection()

	stmt, err := connection.Prepare(sql)
	if err != nil {
		log.Println(err.Error())
		return false
	}
	_, err = stmt.Exec()
	if err != nil {
		log.Println(err.Error())
		return false
	}
	return true
}

func dbQuery(sql string) *sql.Rows {
	log.Println(sql)
	connection = getConnection()
	row, err := connection.Query(sql)

	if err != nil {
		log.Println(err.Error())
		return nil
	}
	return row
}

//Just for demo
func dbinit() {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/", user, pwd, host, port)
	log.Println(dsn)

	timer1 := time.NewTimer(15 * time.Second)
	<-timer1.C

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Printf(err.Error())
		return
	}
	cdb := fmt.Sprintf("CREATE DATABASE %s;", dbname)
	log.Println(cdb)
	_, err = db.Exec(cdb)

	for err != nil {
		log.Printf("init db failed %s \n", err.Error())
		log.Printf("Retrying...........")
		timer1 = time.NewTimer(10 * time.Second)
		<-timer1.C
		_, err = db.Exec(cdb)
	}

	log.Println("Successfully created database")

	udb := fmt.Sprintf("use %s;", dbname)
	_, err = db.Exec(udb)
	if err != nil {
		log.Println(err.Error())
		return
	}
	log.Printf("Switch to db %s \n", dbname)

	connection = db

	// create product table
	ctable := fmt.Sprintf("CREATE Table %s(orderId int NOT NULL AUTO_INCREMENT, custId varchar(50), orderName varchar(30), orderState int,PRIMARY KEY (orderId));", tablename)
	if dbExec(ctable) {
		log.Printf("Table %s created", tablename)
	}
	// create user table
	ctable = fmt.Sprintf("CREATE Table %s(userId int NOT NULL AUTO_INCREMENT, username varchar(50), password varchar(50), role int,PRIMARY KEY (userId));", usertable)

	if dbExec(ctable) {
		log.Printf("Table %s created", usertable)
	}
	// Insert admin user
	initUser := fmt.Sprintf("INSERT INTO %s (username, password, role) VALUES (\"%s\", \"%s\", 0)", usertable, "admin", "1234")

	if dbExec(initUser) {
		log.Println("Admin user created")
	}

	defer db.Close()
	connection = nil
}

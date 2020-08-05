package main

import (
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
)

var (
	authenticated = false
)

// LoginHandler ... render login if get request, otherwise hand off to perform authentication
func loginHandler(w http.ResponseWriter, r *http.Request) {

	//Hardcode credentials
	AccessKeyID := "AKIA2E0A8F3B244C9986"
	SecretKey := "7CE556A3BC234CC1FF9E8A5C324C0BB70AA21B6D"
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}
	TxnsDir := path + "/rolling/transactions"
	log.Printf(" AWS Properties are %s and %s", AccessKeyID, SecretKey)
	log.Printf("Transactions Folder is %s", TxnsDir)

	if r.Method == "GET" {
		t, _ := template.ParseFiles("view/login.html")
		t.Execute(w, nil)
	} else {
		authCheck(w, r)
	}
}

// LogoutHandler ... /logout
func logoutHandler(w http.ResponseWriter, r *http.Request) {
	authenticated = false
	enforcer(w, r, authenticated)
}

func enforcer(w http.ResponseWriter, r *http.Request, authed bool) {
	if authed == false {
		http.Redirect(w, r, "/login", http.StatusFound)
	}
}

// eventually modify this method to call out to authentication service
func authCheck(w http.ResponseWriter, r *http.Request) {
	user := r.FormValue("username")
	pwd := r.FormValue("password")
	if checkUser(user, pwd) {
		authenticated = true
		http.Redirect(w, r, "/app", http.StatusFound)
	} else {
		http.Error(w, "User is not exist or password is not correct", http.StatusForbidden)
	}
	log.Println(user, pwd)
}

func checkUser(user string, pwd string) bool {
	sql := fmt.Sprintf("SELECT * FROM %s WHERE username = \"%s\" AND password = \"%s\";", usertable, user, pwd)
	row := dbQuery(sql)
	defer row.Close()
	if row.Next() {
		return true
	}
	return false
}

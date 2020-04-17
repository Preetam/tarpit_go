package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
)

func main() {

	rtr := mux.NewRouter()
	http.Handle("/", rtr)

	// routes
	rtr.HandleFunc("/", loginHandler)
	rtr.HandleFunc("/login", loginHandler)
	rtr.HandleFunc("/logout", logoutHandler)
	rtr.HandleFunc("/processOrder", processHandler)
	rtr.HandleFunc("/getOrderStatus", statusHandler)
	rtr.HandleFunc("/app", appHandler)
	//rtr.HandleFunc("/dbinit", dbinitHandler)
	//rtr.HandleFunc("/FileUploader", servicesHandler)
	rtr.HandleFunc("/vulns", vulnsHandler)
	rtr.HandleFunc("/profile", proHandler)
	//rtr.HandleFunc("/insider", insiderHandler)
	rtr.HandleFunc("/setprofile", setproHandler)
	rtr.HandleFunc("/traversal", traversalHandler)
	rtr.HandleFunc("/listdemo", listdemoHandler)
	rtr.HandleFunc("/exec", execHandler)
	rtr.HandleFunc("/insider", insiderHandler)

	HomeFolder, _ := os.Getwd()
	rtr.PathPrefix("/image/").Handler(http.StripPrefix("/image/", http.FileServer(http.Dir(HomeFolder+"/image/"))))
	rtr.PathPrefix("/demo/").Handler(http.StripPrefix("/demo/", http.FileServer(http.Dir(HomeFolder+"/demo/"))))

	// listen to the web request
	log.Println("Listening...")
	dbinit()
	http.ListenAndServe(":3000", nil)
}

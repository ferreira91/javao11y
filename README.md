# Book CRUD API - o11y

A RESTful API built using Spring Boot 3 to manage books.

## 🛠 Technologies

- Spring Boot 3
- Spring Data JPA
- H2 in-memory database
- Maven
- Docker

## 🚀 Setup & Running

1. Clone this repo:
   git clone [YOUR_REPOSITORY_URL]
   cd [YOUR_DIRECTORY_NAME]

arduino
Copy code

2. Run using Maven:
   ./mvnw spring-boot:run

markdown
Copy code
This starts the server on port 8080.

3. Docker commands:
- Build: `make docker-build`
- Run: `make docker-run`

## 📘 Endpoints

- List all books: `GET /books`
- Create a book: `POST /books` with body:
```json
{
 "title": "Your Book Title",
 "author": "Author's Name"
}
```
- Get a book by ID: `GET /books/{id}`  
- Update a book: `PUT /books/{id}` with the updated book's body
- Delete a book: `DELETE /books/{id}`

🔍 Testing
Use Postman or Insomnia. Import the insomnia_collections if available.
package com.example.javao11y;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/books")
public class BookController {

    private static final Logger logger = LogManager.getLogger(BookController.class);

    @Autowired
    private BookRepository bookRepository;

    @GetMapping
    public List<Book> list() {
        logger.info("List Books");
        return bookRepository.findAll();
    }

    @PostMapping
    public Book create(@RequestBody Book book) {
        logger.info("Create Book");
        return bookRepository.save(book);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Book> getById(@PathVariable Long id) {
        logger.info("Get Book");
        return bookRepository.findById(id).map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Book> update(@PathVariable Long id, @RequestBody Book updatedBook) {
        logger.info("Update Book");
        return bookRepository.findById(id).map(book -> {
            book.setTitle(updatedBook.getTitle());
            book.setAuthor(updatedBook.getAuthor());
            Book savedBook = bookRepository.save(book);
            return ResponseEntity.ok(savedBook);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        logger.info("Delete Book");
        if (!bookRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }

        bookRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract BookStore {

    address public owner;

    struct Book {
        string title;
        string author;
        uint price;
        uint256 stock;
        bool isAvailable;
    }

    mapping(uint256 => Book) public books;

    uint256[] public bookIds;

    event BookAdded(uint256 indexed bookId, string title, string author, uint256 price, uint256 stock);
    event BookPurchased(uint256 indexed bookId, address indexed buyer, uint256 quantity);

    constructor(address _owner) {
        owner = _owner;
    }

    function addBook(uint256 _bookId, string memory _title, string memory _author, uint256 _price, uint256 _stock) public {
        require(books[_bookId].price == 0, "Book already exists with this ID.");
        books[_bookId] = Book({
            title: _title,
            author: _author,
            price: _price,
            stock: _stock,
            isAvailable: _stock > 0
        });
        bookIds.push(_bookId);
        emit BookAdded(_bookId, _title, _author, _price, _stock);
    }

    function getBooks(uint256 _bookId) public view returns (string memory, string memory, uint256, uint256, bool) {
        Book memory book = books[_bookId];
        return (book.title, book.author, book.price, book.stock, book.isAvailable);
    }

    function buyBook(uint256 _bookId, uint256 _quantity, uint256 _amount) public payable {
        Book storage book = books[_bookId];
        require(book.isAvailable, "This book is not available.");
        require(book.stock >= _quantity, "Not enough stock available.");
        require(_amount == book.price * _quantity, "Incorrect payment amount.");

        book.stock -= _quantity;
        if (book.stock == 0) {
            book.isAvailable = false;
        }

        payable(owner).transfer(msg.value);
        emit BookPurchased(_bookId, msg.sender, _quantity);
    }
}

contract AdvancedBookStore is BookStore {
    mapping(uint256 => bool) public bestsellers;
    uint256 public totalBooksSold;
    uint256 public ownerBalance;

    event BookRemoved(uint256 indexed bookId);
    event BookMarkedAsBestseller(uint256 indexed bookId);

    constructor(address _owner) BookStore(_owner) {}

    function markAsBestseller(uint256 _bookId) public onlyOwner {
        require(books[_bookId].price != 0, "Book does not exist.");
        bestsellers[_bookId] = true;
        emit BookMarkedAsBestseller(_bookId);
    }

    function isBestseller(uint256 _bookId) public view returns (bool) {
        return bestsellers[_bookId];
    }

    function removeBook(uint256 _bookId) public onlyOwner {
        require(books[_bookId].price != 0, "Book does not exist.");
        delete books[_bookId];

        for (uint256 i = 0; i < bookIds.length; i++) {
            if (bookIds[i] == _bookId) {
                bookIds[i] = bookIds[bookIds.length - 1];
                bookIds.pop();
                break;
            }
        }

        if (bestsellers[_bookId]) {
            delete bestsellers[_bookId];
        }

        emit BookRemoved(_bookId);
    }

    function getAllBooks() public view returns (Book[] memory) {
        Book[] memory allBooks = new Book[](bookIds.length);
        for (uint256 i = 0; i < bookIds.length; i++) {
            allBooks[i] = books[bookIds[i]];
        }
        return allBooks;
    }

    function removeAllBooks() public onlyOwner {
        for (uint256 i = 0; i < bookIds.length; i++) {
            delete books[bookIds[i]];
        }
        delete bookIds;
    }

    function getOwnerBalance() public view returns (uint256) {
        return owner.balance;
    }

    function buyBook(uint256 _bookId, uint256 _quantity, uint256 _amount) public payable override {
        super.buyBook(_bookId, _quantity, _amount);
        totalBooksSold += _quantity;
        ownerBalance += msg.value;
    }
}
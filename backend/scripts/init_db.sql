/*
DB-first bootstrap script for SneakersShopBackend

Default database: SneakersShopDb
Default SQL Server instance: (localdb)\MSSQLLocalDB

Seed credentials for local development:
- Admin: admin@sneakershop.local / Admin@123
- User : user@sneakershop.local / User@123

Note:
- Passwords are seeded as plain text only for local DB-first setup convenience.
- The backend automatically upgrades seeded plain-text passwords to BCrypt
  after the first successful login.
*/

SET NOCOUNT ON;
GO

IF DB_ID(N'SneakersShopDb') IS NULL
BEGIN
    CREATE DATABASE SneakersShopDb;
END
GO

USE SneakersShopDb;
GO

IF OBJECT_ID(N'dbo.CartItems', N'U') IS NOT NULL DROP TABLE dbo.CartItems;
IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID(N'dbo.Reviews', N'U') IS NOT NULL DROP TABLE dbo.Reviews;
IF OBJECT_ID(N'dbo.ProductVariants', N'U') IS NOT NULL DROP TABLE dbo.ProductVariants;
IF OBJECT_ID(N'dbo.Shoes', N'U') IS NOT NULL DROP TABLE dbo.Shoes;
IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Email NVARCHAR(256) NOT NULL,
    Password NVARCHAR(256) NOT NULL,
    FullName NVARCHAR(256) NOT NULL,
    Role NVARCHAR(50) NOT NULL CONSTRAINT DF_Users_Role DEFAULT N'User'
);
GO

CREATE UNIQUE INDEX UX_Users_Email ON dbo.Users(Email);
GO

CREATE TABLE dbo.Shoes
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(256) NOT NULL,
    Brand NVARCHAR(256) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    ImageUrl NVARCHAR(1024) NOT NULL
);
GO

CREATE TABLE dbo.ProductVariants
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShoeId INT NOT NULL,
    Size NVARCHAR(20) NOT NULL,
    Color NVARCHAR(80) NOT NULL,
    Stock INT NOT NULL CONSTRAINT DF_ProductVariants_Stock DEFAULT 0,
    CONSTRAINT FK_ProductVariants_Shoes
        FOREIGN KEY (ShoeId) REFERENCES dbo.Shoes(Id) ON DELETE CASCADE,
    CONSTRAINT CK_ProductVariants_Stock_NonNegative CHECK (Stock >= 0)
);
GO

CREATE UNIQUE INDEX UX_ProductVariants_Shoe_Size_Color
    ON dbo.ProductVariants(ShoeId, Size, Color);
GO

CREATE TABLE dbo.Reviews
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShoeId INT NOT NULL,
    UserId INT NOT NULL,
    Rating INT NOT NULL,
    Comment NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Reviews_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Reviews_Shoes
        FOREIGN KEY (ShoeId) REFERENCES dbo.Shoes(Id) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Users
        FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Reviews_Rating CHECK (Rating BETWEEN 1 AND 5)
);
GO

CREATE TABLE dbo.Orders
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UserId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT SYSUTCDATETIME(),
    Status NVARCHAR(50) NOT NULL CONSTRAINT DF_Orders_Status DEFAULT N'Pending',
    TotalAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_Orders_TotalAmount DEFAULT 0,
    CONSTRAINT FK_Orders_Users
        FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Orders_Status CHECK (Status IN (N'Pending', N'Confirmed', N'Preparing', N'Shipping', N'Completed'))
);
GO

CREATE TABLE dbo.OrderItems
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrderId INT NOT NULL,
    ShoeId INT NOT NULL,
    ProductVariantId INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Shoes
        FOREIGN KEY (ShoeId) REFERENCES dbo.Shoes(Id),
    CONSTRAINT FK_OrderItems_ProductVariants
        FOREIGN KEY (ProductVariantId) REFERENCES dbo.ProductVariants(Id),
    CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_Price CHECK (Price >= 0)
);
GO

CREATE INDEX IX_OrderItems_OrderId ON dbo.OrderItems(OrderId);
CREATE INDEX IX_OrderItems_ShoeId ON dbo.OrderItems(ShoeId);
GO

CREATE TABLE dbo.CartItems
(
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UserId INT NOT NULL,
    ShoeId INT NOT NULL,
    ProductVariantId INT NOT NULL,
    Quantity INT NOT NULL,
    CONSTRAINT FK_CartItems_Users
        FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_Shoes
        FOREIGN KEY (ShoeId) REFERENCES dbo.Shoes(Id) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_ProductVariants
        FOREIGN KEY (ProductVariantId) REFERENCES dbo.ProductVariants(Id) ON DELETE CASCADE,
    CONSTRAINT CK_CartItems_Quantity CHECK (Quantity > 0)
);
GO

CREATE UNIQUE INDEX UX_CartItems_User_Shoe_Variant
    ON dbo.CartItems(UserId, ShoeId, ProductVariantId);
GO

INSERT INTO dbo.Users (Email, Password, FullName, Role) VALUES
(N'admin@sneakershop.local', N'Admin@123', N'Shop Owner', N'Admin'),
(N'user@sneakershop.local', N'User@123', N'Demo User', N'User');
GO

INSERT INTO dbo.Shoes (Name, Brand, Description, Price, ImageUrl) VALUES
(N'Air Max 90', N'Nike', N'Classic Nike lifestyle sneaker with layered panels and everyday comfort.', 120.00, N'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1000&q=80'),
(N'Ultraboost Light', N'Adidas', N'Responsive running shoe for daily use with lightweight cushioning.', 180.00, N'https://images.unsplash.com/photo-1608231387042-66d1773070a5?auto=format&fit=crop&w=1000&q=80'),
(N'574 Core', N'New Balance', N'Retro runner silhouette suited for casual outfits and all-day wear.', 95.00, N'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=1000&q=80'),
(N'Chuck Taylor High', N'Converse', N'Timeless high-top sneaker for casual streetwear styling.', 70.00, N'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?auto=format&fit=crop&w=1000&q=80'),
(N'Jordan 1 Mid', N'Nike', N'Basketball-inspired icon with bold overlays and durable construction.', 165.00, N'https://images.unsplash.com/photo-1552346154-21d32810aba3?auto=format&fit=crop&w=1000&q=80');
GO

INSERT INTO dbo.ProductVariants (ShoeId, Size, Color, Stock) VALUES
(1, N'39', N'White/Red', 10),
(1, N'40', N'White/Red', 12),
(1, N'41', N'Black', 8),
(2, N'40', N'Core Black', 9),
(2, N'41', N'Core Black', 11),
(2, N'42', N'Cloud White', 6),
(3, N'39', N'Grey', 13),
(3, N'40', N'Grey', 14),
(3, N'41', N'Navy', 7),
(4, N'38', N'Black', 16),
(4, N'39', N'Black', 12),
(4, N'40', N'White', 9),
(5, N'40', N'Red/Black', 5),
(5, N'41', N'Red/Black', 7),
(5, N'42', N'White/Grey', 4);
GO

INSERT INTO dbo.Reviews (ShoeId, UserId, Rating, Comment) VALUES
(1, 2, 5, N'Form dep va di rat em chan.'),
(1, 2, 4, N'Chat luong tot, giao hang nhanh.'),
(2, 2, 5, N'Di bo va tap nhe rat on.');
GO

INSERT INTO dbo.Orders (UserId, OrderDate, Status, TotalAmount) VALUES
(2, DATEADD(DAY, -7, SYSUTCDATETIME()), N'Completed', 330.00),
(2, DATEADD(DAY, -2, SYSUTCDATETIME()), N'Shipping', 120.00);
GO

INSERT INTO dbo.OrderItems (OrderId, ShoeId, ProductVariantId, Quantity, Price) VALUES
(1, 3, 7, 1, 95.00),
(1, 4, 10, 1, 70.00),
(1, 5, 14, 1, 165.00),
(2, 1, 1, 1, 120.00);
GO

INSERT INTO dbo.CartItems (UserId, ShoeId, ProductVariantId, Quantity) VALUES
(2, 1, 2, 1),
(2, 2, 4, 2);
GO

PRINT N'SneakersShopDb schema and seed data created successfully.';
GO

<?php
include 'db.php';
$action = $_GET['action'] ?? '';

if ($action == 'register') {
    $data = json_decode(file_get_contents("php://input"), true);
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        echo json_encode(["success" => false, "message" => "Email and password are required"]);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO users (email, password) VALUES (?, ?)");
    $stmt->bind_param("ss", $email, $password);
    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Account created successfully", "user_id" => $stmt->insert_id]);
    } else {
        echo json_encode(["success" => false, "message" => "Email already exists or registration failed"]);
    }
} 
else if ($action == 'login') {
    $data = json_decode(file_get_contents("php://input"), true);
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    
    $stmt = $conn->prepare("SELECT id, email FROM users WHERE email = ? AND password = ?");
    $stmt->bind_param("ss", $email, $password);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode(["success" => true, "message" => "Login successful", "user_id" => $row['id'], "email" => $row['email']]);
    } else {
        echo json_encode(["success" => false, "message" => "Invalid email or password"]);
    }
}
else if ($action == 'get_categories') {
    $result = $conn->query("SELECT * FROM categories");
    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categories[] = $row;
    }
    echo json_encode(["success" => true, "data" => $categories]);
}
else if ($action == 'get_transactions') {
    $userId = $_GET['user_id'] ?? 0;
    $stmt = $conn->prepare("SELECT t.*, c.name as category_name FROM transactions t JOIN categories c ON t.category_id = c.id WHERE t.user_id = ? ORDER BY t.date DESC");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $transactions = [];
    while ($row = $result->fetch_assoc()) {
        $transactions[] = $row;
    }
    echo json_encode(["success" => true, "data" => $transactions]);
}
else if ($action == 'add_transaction') {
    $data = json_decode(file_get_contents("php://input"), true);
    $stmt = $conn->prepare("INSERT INTO transactions (user_id, title, amount, type, category_id, date) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("isdsis", $data['user_id'], $data['title'], $data['amount'], $data['type'], $data['category_id'], $data['date']);
    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Transaction added successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error adding transaction"]);
    }
}
else if ($action == 'delete_transaction') {
    $id = $_GET['id'] ?? 0;
    $stmt = $conn->prepare("DELETE FROM transactions WHERE id = ?");
    $stmt->bind_param("i", $id);
    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Transaction deleted"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error deleting transaction"]);
    }
}
?>
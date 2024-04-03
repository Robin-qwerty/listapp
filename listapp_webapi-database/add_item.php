<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the required parameters are provided
if (!isset($_POST['userId']) || !isset($_POST['listId']) || !isset($_POST['itemName'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    // Assign parameters to variables
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];
    $itemName = $_POST['itemName'];

    // Prepare and execute SQL statement to check if user exists
    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    // Check if user exists
    if ($user) {
        // Prepare and execute SQL statement to insert new item
        $query = "INSERT INTO items (`list-id`, item_name) VALUES (?, ?)";
        $statement = $conn->prepare($query);
        $statement->execute([$listId, $itemName]);
        $item = $statement->fetch(PDO::FETCH_ASSOC);
        // Return the inserted item data
        echo json_encode(['success' => true, 'item' => $item]);
    } else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (PDOException $e) {
    // Error handling
    echo json_encode(['error' => 'Failed to add item: ' . $e->getMessage()]);
}
?>

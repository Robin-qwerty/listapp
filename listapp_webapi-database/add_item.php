<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (!isset($_POST['userId']) || !isset($_POST['listId']) || !isset($_POST['itemName'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];
    $itemName = $_POST['itemName'];

    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $query = "INSERT INTO items (`listid`, item_name) VALUES (?, ?)";
        $statement = $conn->prepare($query);
        $statement->execute([$listId, $itemName]);
        $item = $statement->fetch(PDO::FETCH_ASSOC);

        echo json_encode(['success' => true, 'item' => $item]);
    } else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to add item: ' . $e->getMessage()]);
}
?>

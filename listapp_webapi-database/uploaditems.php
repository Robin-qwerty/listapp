<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (isset($_POST['userId']) && isset($_POST['items'])) {
    $userId = $_POST['userId'];
    $items = json_decode($_POST['items'], true)['items'];

    // try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            foreach ($items as $item) {
                if ($item['uploaded'] == 2) {
                    // Create new item
                    $insertQuery = "INSERT INTO items (listid, item_name, archive) VALUES (?, ?, ?)";
                    $insertStatement = $conn->prepare($insertQuery);
                    $insertStatement->execute([$item['listid'], $item['item_name'], $item['archive']]);
                } else {
                    // Update existing item
                    $updateQuery = "UPDATE items SET item_name = ?, archive = ? WHERE id = ?";
                    $updateStatement = $conn->prepare($updateQuery);
                    $updateStatement->execute([$item['item_name'], $item['archive'], $item['id']]);
                }
            }
            
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Invalid userId']);
        }
    // } catch (PDOException $e) {
    //     echo json_encode(['error' => 'Failed to fetch items: ' . $e->getMessage()]);
    // }
} else {
    echo json_encode(['error' => 'userId or items are not provided']);
}
?>

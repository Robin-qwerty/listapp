<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userId']) && isset($_POST['listId']) || isset($_POST['itemName']) || isset($_POST['itemId']) || isset($_POST['archiveStatus']) || isset($_POST['staredStatus'])) {
    $userId = $_POST['userId'];
    if (isset($_POST['listId'])) {$listId = $_POST['listId'];}
    if (isset($_POST['itemName'])) {$itemName = $_POST['itemName'];}
    if (isset($_POST['itemId'])) {$itemId = $_POST['itemId'];}

    try {
        $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $user = $statement->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            if (isset($_POST['archiveStatus'])) {
                $archiveStatus = $_POST['archiveStatus'];

                $updateQuery = "UPDATE items SET archive = ? WHERE id = ?";
                $updateStatement = $conn->prepare($updateQuery);
                $updateStatement->execute([$archiveStatus, $itemId]);
                echo json_encode(['success' => true, 'message' => 'Item archiveStatus updated successfully']);
            } elseif (isset($_POST['staredStatus'])) {
                $staredStatus = $_POST['staredStatus'];

                $updateQuery = "UPDATE items SET stared = ? WHERE id = ?";
                $updateStatement = $conn->prepare($updateQuery);
                $updateStatement->execute([$staredStatus, $itemId]);
                echo json_encode(['success' => true, 'message' => 'Item staredStatus updated successfully']);
            } elseif (isset($_POST['itemName'])) {

                $updateQuery = "UPDATE items SET item_name = ? WHERE id = ?";
                $updateStatement = $conn->prepare($updateQuery);
                $updateStatement->execute([$itemName, $itemId]);
                echo json_encode(['success' => true, 'message' => 'Item name updated successfully']);
            } else {
                $query = "SELECT * FROM items WHERE `listid` = ? AND archive != 2 ORDER BY 
                    CASE 
                    WHEN stared = 1 AND archive = 0 THEN 0
                    WHEN archive = 0 THEN 1
                    WHEN archive = 1 THEN 2
                    END";
                $statement = $conn->prepare($query);
                $statement->execute([$listId]);
                $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

                header('Content-Type: application/json');
                echo json_encode($lists);
            }
        } else {
            echo json_encode(['error' => 'Invalid user']);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to perform action: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userId or listId is not provided']);
}
?>
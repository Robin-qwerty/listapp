<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// // Check if userId and listId are provided in the POST request
// if (isset($_POST['userId'], $_POST['listId'])) {
//     // Retrieve userId and listId from POST request
//     $userId = $_POST['userId'];
//     $listId = $_POST['listId'];

//     try {
//         // Check if the user exists in the database
//         $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
//         $statement = $conn->prepare($query);
//         $statement->execute([$userId]);
//         $user = $statement->fetch(PDO::FETCH_ASSOC);

//         if ($user) {
//             // Prepare SQL statement to fetch items for the given list ID
//             $query = "SELECT * FROM items WHERE `list-id` = ? AND archive != 2 ORDER BY archive ASC";
//             $statement = $conn->prepare($query);
//             $statement->execute([$listId]);
//             $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

//             header('Content-Type: application/json');
//             echo json_encode($lists);
//         } else {
//             // User does not exist
//             echo json_encode(['error' => 'Invalid user']);
//         }
//     } catch (PDOException $e) {
//         // Error handling if the query fails
//         echo json_encode(['error' => 'Failed to fetch items: ' . $e->getMessage()]);
//     }
// } else {
//     // Error handling if userId or listId is not provided
//     echo json_encode(['error' => 'userId or listId is not provided']);
// }



if (isset($_POST['userId']) && isset($_POST['listId']) || isset($_POST['itemName']) || isset($_POST['itemId']) || isset($_POST['archiveStatus'])) {
    $userId = $_POST['userId'];
    if (isset($_POST['listId'])) {$listId = $_POST['listId'];}
    if (isset($_POST['itemName'])) {$itemName = $_POST['itemName'];}
    if (isset($_POST['itemId'])) {$itemId = $_POST['itemId'];}

    try {
        // Check if the user exists in the database
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
                echo json_encode(['success' => true, 'message' => 'Item name updated successfully']);
            } elseif (isset($_POST['itemName'])) {

                $updateQuery = "UPDATE items SET item_name = ? WHERE id = ?";
                $updateStatement = $conn->prepare($updateQuery);
                $updateStatement->execute([$itemName, $itemId]);
                echo json_encode(['success' => true, 'message' => 'Item name updated successfully']);
            } else {
                $query = "SELECT * FROM items WHERE `list-id` = ? AND archive != 2 ORDER BY archive ASC";
                $statement = $conn->prepare($query);
                $statement->execute([$listId]);
                $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

                header('Content-Type: application/json');
                echo json_encode($lists);
            }
        } else {
            // User does not exist
            echo json_encode(['error' => 'Invalid user']);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to perform action: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userId or listId is not provided']);
}
?>
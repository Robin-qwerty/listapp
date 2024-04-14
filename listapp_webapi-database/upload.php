<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (isset($_POST['userid']) && isset($_POST['lists']) && isset($_POST['items'])) {
    $userId = $_POST['userid'];
    $lists = json_decode($_POST['lists'], true)['lists'];
    $items = json_decode($_POST['items'], true)['items'];

    $changedListIds = [];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            $lastInsertedListId = null;
            $previousListId = null;

            foreach ($lists as $list) {
                if ($list['uploaded'] == 2) {
                    $previousListId = $list['id'];

                    $insertQuery = "INSERT INTO lists (userid, name, archive) VALUES (?, ?, ?)";
                    $insertStatement = $conn->prepare($insertQuery);
                    $insertStatement->execute([$userId, $list['name'], $list['archive']]);

                    $lastInsertedListId = $conn->lastInsertId();
                } else {
                    $updateQuery = "UPDATE lists SET name = ?, archive = ? WHERE id = ?";
                    $updateStatement = $conn->prepare($updateQuery);
                    $updateStatement->execute([$list['name'], $list['archive'], $list['id']]);
                }

                foreach ($items as &$item) {
                    if ($previousListId == $item['listid']) {
                        $item['listid'] = $lastInsertedListId;
                        $changedListIds[] = $item['listid'];
                    }
                }
                unset($item);
            }

            foreach ($items as $item) {
                if ($item['uploaded'] == 2) {
                    $insertQuery = "INSERT INTO items (listid, item_name, archive) VALUES (?, ?, ?)";
                    $insertStatement = $conn->prepare($insertQuery);
                    $insertStatement->execute([$item['listid'], $item['item_name'], $item['archive']]);
                } else {
                    $updateQuery = "UPDATE items SET item_name = ?, archive = ? WHERE id = ?";
                    $updateStatement = $conn->prepare($updateQuery);
                    $updateStatement->execute([$item['item_name'], $item['archive'], $item['id']]);
                }
            }
            
            echo json_encode(['success' => true, 'changedListIds' => $changedListIds]);
        } else {
            echo json_encode(['error' => 'Invalid userId']);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to upload lists and items: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userid, lists, or items are not provided']);
}
?>

<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userid'])) {
    $userId = $_POST['userid'];

    $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $row = $statement->fetch(PDO::FETCH_ASSOC);

    if ($row['count'] > 0) {
        if (isset($_POST['posixTime']) && isset($_POST['listid'])) {
            $listid = $_POST['listid'];
            $posixTime = $_POST['posixTime'];
            
            try {
                $updateQuery = "UPDATE lists SET last_opened = :posixTime WHERE id = :listid AND userid = :userId";
                $updateStatement = $conn->prepare($updateQuery);
                $updateStatement->bindParam(':posixTime', $posixTime, PDO::PARAM_INT);
                $updateStatement->bindParam(':listid', $listid, PDO::PARAM_INT);
                $updateStatement->bindParam(':userId', $userId, PDO::PARAM_STR);
                $updateStatement->execute();
                
                echo json_encode(['success' => true]);
            } catch (PDOException $e) {
                echo json_encode(['error' => 'Failed to update POSIX time: ' . $e->getMessage()]);
            }
        } else {
            try {
                $query = "SELECT l.*, COALESCE(COUNT(g.id), 0) AS shared_with_count
                    FROM lists l
                    LEFT OUTER JOIN listgrouplink lg ON l.id = lg.listid
                    LEFT OUTER JOIN listgroup g ON lg.id = g.listgrouplinkid
                    WHERE l.userid = :userId AND l.archive = 0
                    GROUP BY l.id
                    ORDER BY l.last_opened DESC";
                $statement = $conn->prepare($query);
                $statement->bindParam(':userId', $userId, PDO::PARAM_STR);
                $statement->execute();
                $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

                header('Content-Type: application/json');
                echo json_encode($lists);
            } catch (PDOException $e) {
                echo json_encode(['error' => 'Failed to fetch lists: ' . $e->getMessage()]);
            }
        }
    } else {
        echo json_encode(['error' => 'Invalid userId']);
    }
} else {
    echo json_encode(['error' => 'userid is not provided']);
}
?>

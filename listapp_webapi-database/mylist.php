<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (isset($_POST['userid'])) {
    $userId = $_POST['userid'];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            $query = "SELECT l.*, COALESCE(COUNT(g.id), 0) AS shared_with_count
                FROM lists l
                LEFT OUTER JOIN listgrouplink lg ON l.id = lg.listid
                LEFT OUTER JOIN listgroup g ON lg.id = g.listgrouplinkid
                WHERE l.userid = ? AND l.archive = 0
                GROUP BY l.id";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);
            $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

            header('Content-Type: application/json');
            echo json_encode($lists);
        } else {
            echo json_encode(['error' => 'Invalid userId']);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to fetch lists: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userid is not provided']);
}
?>

<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (isset($_POST['userId']) && isset($_POST['listId'])) {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            $query = "SELECT id FROM listgrouplink WHERE owner = ? AND listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId, $listId]);
            $listGrouplinkId = $statement->fetchColumn();

            if (!$listGrouplinkId) {
                $query = "INSERT INTO listgrouplink (owner, listid) VALUES (?, ?)";
                $statement = $conn->prepare($query);
                $statement->execute([$userId, $listId]);

                $listGrouplinkId = $conn->lastInsertId();
            }

            $query = "SELECT code FROM invite WHERE groupid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$listGrouplinkId]);
            $existingCode = $statement->fetchColumn();

            if (!$existingCode) {
                $code = generateUniqueCode();

                $query = "INSERT INTO invite (groupid, code) VALUES (?, ?)";
                $statement = $conn->prepare($query);
                $statement->execute([$listGrouplinkId, $code]);
            } else {
                $code = $existingCode;
            }

            echo json_encode(['success' => true, 'code' => "the group code: $code", 'link' => "https://robin.humilis.net/flutter/listapp/accept_invite.php?code=$code"]);
        } else {
            echo "ERROR3";
        }
    } catch (PDOException $e) {
        echo "ERROR1";
    }
} else {
    echo "ERROR2";
}

function generateUniqueCode() {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $code = '';
    for ($i = 0; $i < 8; $i++) {
        $code .= $characters[rand(0, strlen($characters) - 1)];
    }
    return $code;
}
?>
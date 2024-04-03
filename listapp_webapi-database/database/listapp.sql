-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Gegenereerd op: 03 apr 2024 om 21:42
-- Serverversie: 10.11.3-MariaDB
-- PHP-versie: 8.2.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `listapp`
--

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `items`
--

CREATE TABLE `items` (
  `id` int(11) NOT NULL,
  `list-id` int(11) NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `archive` tinyint(4) NOT NULL DEFAULT 0 COMMENT '1=crossed out\r\n2=deleted'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `items`
--

INSERT INTO `items` (`id`, `list-id`, `item_name`, `archive`) VALUES
(1, 11, 'test 1 edit test', 1),
(2, 11, 'test 2', 0),
(4, 11, 'test 4', 0),
(5, 12, 'test 5', 0),
(6, 11, 'add item 1', 0),
(9, 14, 'dgn vc', 0),
(10, 21, 'dvd ', 0),
(11, 11, 'dydu', 1),
(12, 11, 'd d dbyndv', 1);

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `listgroup`
--

CREATE TABLE `listgroup` (
  `id` int(11) NOT NULL,
  `owner` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `lists`
--

CREATE TABLE `lists` (
  `id` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `listgroup_id` int(11) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `archive` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `lists`
--

INSERT INTO `lists` (`id`, `userid`, `listgroup_id`, `name`, `archive`) VALUES
(1, 0, 0, 'boodschappen', 0),
(3, 0, 0, 'Verlanglijstje Mara', 0),
(4, 0, 0, 'Verlanglijstje Robin', 0),
(5, 0, 0, 'verlanglijstje Suzanne', 0),
(6, 0, 0, 'Verlanglijstje Sander', 0),
(7, 0, 0, 'Taakjes Robin', 0),
(9, 0, 0, 'Fruitschaal', 0),
(11, 1, NULL, 'test lijstje', 0),
(20, 1, NULL, 'Delete list test 2', 0),
(21, 1, NULL, 'edit list name test', 0);

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `tasks`
--

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `list-id` int(11) NOT NULL,
  `task_name` varchar(255) NOT NULL,
  `archive` tinyint(4) NOT NULL DEFAULT 0 COMMENT '1=crossed out\r\n2=deleted'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `tasks`
--

INSERT INTO `tasks` (`id`, `list-id`, `task_name`, `archive`) VALUES
(1, 1, 'melk', 2),
(2, 1, 'yoghurt', 0),
(3, 1, 'brood', 0),
(4, 5, 'leuke dingen', 0),
(5, 5, 'mooie dingen', 0),
(6, 5, 'geinige dingen', 0),
(7, 1, 'Kaas', 0),
(8, 7, 'Stofzuigen', 1),
(17, 4, 'geld?', 0),
(18, 1, 'wfsdfs', 1);

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `users`
--

CREATE TABLE `users` (
  `userid` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `archive` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `edited_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `users`
--

INSERT INTO `users` (`userid`, `username`, `password`, `archive`, `created_at`, `edited_at`, `deleted_at`) VALUES
(1, 'test', '$2y$10$nlmFlzhEpSNck66WlFJnPuB2ygJM7asHzPZUU1TapIjp3Wg8wrbmu', 0, '2024-04-03 12:21:53', '2024-04-03 12:21:53', NULL);

--
-- Indexen voor geëxporteerde tabellen
--

--
-- Indexen voor tabel `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id`);

--
-- Indexen voor tabel `listgroup`
--
ALTER TABLE `listgroup`
  ADD PRIMARY KEY (`id`);

--
-- Indexen voor tabel `lists`
--
ALTER TABLE `lists`
  ADD PRIMARY KEY (`id`);

--
-- Indexen voor tabel `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT voor geëxporteerde tabellen
--

--
-- AUTO_INCREMENT voor een tabel `items`
--
ALTER TABLE `items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT voor een tabel `listgroup`
--
ALTER TABLE `listgroup`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT voor een tabel `lists`
--
ALTER TABLE `lists`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT voor een tabel `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

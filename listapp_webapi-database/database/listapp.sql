-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Gegenereerd op: 06 apr 2024 om 12:29
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
-- Tabelstructuur voor tabel `invite`
--

CREATE TABLE `invite` (
  `id` int(11) NOT NULL,
  `groupid` int(11) NOT NULL,
  `code` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `invite`
--

INSERT INTO `invite` (`id`, `groupid`, `code`) VALUES
(1, 8, 'S6BthhbM'),
(3, 7, 'p71bK002'),
(5, 6, 'h82GwWPB'),
(8, 32, 'ZF3oPd86'),
(10, 10, 'DcMxOsCX');

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
(1, 11, 'test 1 edit test', 0),
(2, 11, 'test 2', 0),
(4, 11, 'test 4', 0),
(5, 32, 'test shared list edit item', 0),
(6, 11, 'add item 1', 0),
(9, 14, 'dgn vc', 0),
(10, 21, 'dvd ', 0),
(11, 11, 'dydu', 0),
(13, 29, 'kaas', 0),
(14, 29, 'melk 2x', 0),
(16, 30, 'melk', 0),
(17, 30, 'brood', 0),
(18, 32, 'dyfydu', 0),
(19, 11, 'tebdbx', 1),
(20, 11, 'jsns chdhndnd 47283', 2),
(21, 32, '63784 78283', 2),
(22, 32, 'hv', 1);

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `listgroup`
--

CREATE TABLE `listgroup` (
  `id` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `listgrouplinkid` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `listgroup`
--

INSERT INTO `listgroup` (`id`, `userid`, `listgrouplinkid`) VALUES
(25, 2, 8),
(49, 1, 1);

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `listgrouplink`
--

CREATE TABLE `listgrouplink` (
  `id` int(11) NOT NULL,
  `owner` int(11) NOT NULL,
  `listid` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `listgrouplink`
--

INSERT INTO `listgrouplink` (`id`, `owner`, `listid`) VALUES
(1, 2, 32),
(6, 1, 11),
(7, 1, 20),
(8, 1, 21),
(10, 1, 33);

-- --------------------------------------------------------

--
-- Tabelstructuur voor tabel `lists`
--

CREATE TABLE `lists` (
  `id` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `archive` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Gegevens worden geëxporteerd voor tabel `lists`
--

INSERT INTO `lists` (`id`, `userid`, `name`, `archive`) VALUES
(1, 0, 'boodschappen', 0),
(3, 0, 'Verlanglijstje Mara', 0),
(4, 0, 'Verlanglijstje Robin', 0),
(5, 0, 'verlanglijstje Suzanne', 0),
(6, 0, 'Verlanglijstje Sander', 0),
(7, 0, 'Taakjes Robin', 0),
(9, 0, 'Fruitschaal', 0),
(11, 1, 'test lijstje', 0),
(20, 1, 'Delete list test 1', 0),
(21, 1, 'edit list name test', 0),
(29, 2, 'boodschappen ', 0),
(30, 3, 'boodschappen', 0),
(31, 3, 'verlanglijstje', 0),
(32, 2, 'share list test', 0),
(33, 1, 'a list edited', 0),
(34, 1, 'my list edited', 1);

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
(1, 'test', '$2y$10$nlmFlzhEpSNck66WlFJnPuB2ygJM7asHzPZUU1TapIjp3Wg8wrbmu', 0, '2024-04-03 12:21:53', '2024-04-03 12:21:53', NULL),
(2, 'testuser', '$2y$10$0iexwokvGZHZkfxjzQbNP.zx5LtzozzWG4ZJsXAy1ilDY4HMkZcaS', 0, '2024-04-04 08:25:53', '2024-04-04 08:25:53', NULL),
(3, 'Suzanne', '$2y$10$dQIYVJzeeC1R6oEaRCTQeuZgj05BjOk8tKfr.HH.rTjX0CYGf6m0G', 0, '2024-04-04 08:30:09', '2024-04-04 08:30:09', NULL);

--
-- Indexen voor geëxporteerde tabellen
--

--
-- Indexen voor tabel `invite`
--
ALTER TABLE `invite`
  ADD PRIMARY KEY (`id`);

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
-- Indexen voor tabel `listgrouplink`
--
ALTER TABLE `listgrouplink`
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
-- Indexen voor tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`userid`);

--
-- AUTO_INCREMENT voor geëxporteerde tabellen
--

--
-- AUTO_INCREMENT voor een tabel `invite`
--
ALTER TABLE `invite`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT voor een tabel `items`
--
ALTER TABLE `items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT voor een tabel `listgroup`
--
ALTER TABLE `listgroup`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT voor een tabel `listgrouplink`
--
ALTER TABLE `listgrouplink`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT voor een tabel `lists`
--
ALTER TABLE `lists`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT voor een tabel `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT voor een tabel `users`
--
ALTER TABLE `users`
  MODIFY `userid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 21-11-2026 a las 04:44:21
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bd_aplicacion_movil`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `blog`
--

CREATE TABLE `blog` (
  `id_blog` int(11) NOT NULL,
  `titulo` varchar(150) NOT NULL,
  `desc` text DEFAULT NULL,
  `img` varchar(500) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comentarios`
--

CREATE TABLE `comentarios` (
  `id_com` int(11) NOT NULL,
  `comentario` text NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `estatus` int(11) NOT NULL DEFAULT 1,
  `usr_id` int(11) NOT NULL,
  `blog_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id_usr` int(11) NOT NULL,
  `nom_usr` varchar(100) NOT NULL,
  `mail` varchar(150) NOT NULL,
  `pass` varchar(255) NOT NULL,
  `dir_usr` varchar(200) DEFAULT NULL,
  `tip_usu` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id_usr`, `nom_usr`, `mail`, `pass`, `dir_usr`, `tip_usu`) VALUES
(5, 'prueba2', 'prueba2@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$1fvNjHOFmF/CtTFmLDc0qg$JWPPzxCJYHbVYhUmdT2bqPKezTedkP32arX2YdaiJOA', NULL, 2),
(10, 'admin2', 'admin2@blog.com', '$argon2id$v=19$m=65536,t=3,p=4$G0c+mJtEzgbuXJaNOOEEvA$8HAq88hOs4VYtilWlhkERVXgHiLA59Yp+r38Sr8t4z8', NULL, 1),
(12, 'Alumno', 'prueba@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$hQbbP05dVtzNBiQIm2JC3Q$EdvxUVOED42F3zoPkiM/68GpizpiyQjSl4q2AXMgWDk', NULL, 2),
(13, 'emiliano', 'rodriguezbrnbe@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$DC402oQbD9d9f05BaMDYKg$TvXgQIn1TZYhzlioC2kkjTHIk61MpEkPYeUb6C38hwY', NULL, 2),
(15, 'adminprueba', '345@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$Iv+10v5Bz22Fjo6asuBaKA$+jLVd7NvWpZwm9WSMMCAyzm8GxJgg8sGnVr1UY4Nr7c', NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `valoraciones`
--

CREATE TABLE `valoraciones` (
  `id_val` int(11) NOT NULL,
  `estrellas` int(11) NOT NULL,
  `usr_id` int(11) NOT NULL,
  `blog_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `blog`
--
ALTER TABLE `blog`
  ADD PRIMARY KEY (`id_blog`);

--
-- Indices de la tabla `comentarios`
--
ALTER TABLE `comentarios`
  ADD PRIMARY KEY (`id_com`),
  ADD KEY `fk_comentario_usuario` (`usr_id`),
  ADD KEY `fk_comentario_blog` (`blog_id`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id_usr`),
  ADD UNIQUE KEY `mail` (`mail`);

--
-- Indices de la tabla `valoraciones`
--
ALTER TABLE `valoraciones`
  ADD PRIMARY KEY (`id_val`),
  ADD UNIQUE KEY `uq_usuario_blog` (`usr_id`,`blog_id`),
  ADD KEY `fk_val_blog` (`blog_id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `blog`
--
ALTER TABLE `blog`
  MODIFY `id_blog` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `comentarios`
--
ALTER TABLE `comentarios`
  MODIFY `id_com` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id_usr` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `valoraciones`
--
ALTER TABLE `valoraciones`
  MODIFY `id_val` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `comentarios`
--
ALTER TABLE `comentarios`
  ADD CONSTRAINT `fk_comentario_blog` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id_blog`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_comentario_usuario` FOREIGN KEY (`usr_id`) REFERENCES `usuario` (`id_usr`);

--
-- Filtros para la tabla `valoraciones`
--
ALTER TABLE `valoraciones`
  ADD CONSTRAINT `fk_val_blog` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id_blog`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_val_usuario` FOREIGN KEY (`usr_id`) REFERENCES `usuario` (`id_usr`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

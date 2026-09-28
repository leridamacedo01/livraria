DROP DATABASE IF EXISTS livraria;
CREATE DATABASE livraria CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE livraria;

CREATE TABLE pessoas (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(100) NOT NULL,
  cpf        CHAR(11)     NOT NULL UNIQUE,
  email      VARCHAR(150),
  telefone   VARCHAR(20),
  nascimento DATE,
  cidade     VARCHAR(80),
  uf         CHAR(2),
  matricula     VARCHAR(20) UNIQUE,
  categoria     ENUM('aluno','professor','servidor','comunidade'),
  limite_livros TINYINT NOT NULL DEFAULT 3  CHECK (limite_livros BETWEEN 1 AND 20),
  prazo_dias    TINYINT NOT NULL DEFAULT 14 CHECK (prazo_dias   BETWEEN 1 AND 180),
  bloqueado     TINYINT(1) NOT NULL DEFAULT 0,
  ativo      TINYINT(1) NOT NULL DEFAULT 1,
  criado_em  DATETIME DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT ck_socio CHECK ((matricula IS NULL AND categoria IS NULL) OR (matricula IS NOT NULL AND categoria IS NOT NULL))
) ENGINE=InnoDB;

CREATE TABLE obras (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  isbn     CHAR(13) UNIQUE,
  titulo   VARCHAR(180) NOT NULL,
  autor    VARCHAR(120) NOT NULL,
  editora  VARCHAR(100),
  edicao   VARCHAR(30),
  ano      SMALLINT,
  genero   ENUM('romance','tecnico','infantil','biografia','autoajuda','didatico','historia','outro') NOT NULL DEFAULT 'outro',
  cdd      VARCHAR(20),
  assunto  VARCHAR(100),
  a_venda       TINYINT(1)    NOT NULL DEFAULT 0,
  preco_venda   DECIMAL(10,2) CHECK (preco_venda >= 0),
  estoque_venda INT NOT NULL DEFAULT 0 CHECK (estoque_venda >= 0),
  CONSTRAINT ck_preco CHECK (a_venda = 0 OR preco_venda IS NOT NULL),
  INDEX idx_obras_titulo (titulo),
  INDEX idx_obras_autor  (autor)
) ENGINE=InnoDB;

CREATE TABLE exemplares (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  obra_id        INT NOT NULL,
  tombo          VARCHAR(20) NOT NULL UNIQUE,
  localizacao    VARCHAR(40),
  aquisicao      DATE,
  situacao       ENUM('disponivel','emprestado','reservado','manutencao','perdido','descartado') NOT NULL DEFAULT 'disponivel',
  consulta_local TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_exemplar_obra FOREIGN KEY (obra_id) REFERENCES obras(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_exemplares_situacao (situacao)
) ENGINE=InnoDB;

CREATE TABLE pedidos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  pessoa_id       INT NOT NULL,
  data_pedido     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status          ENUM('aberto','pago','enviado','entregue','cancelado') NOT NULL DEFAULT 'aberto',
  forma_pagamento ENUM('dinheiro','pix','debito','credito','boleto'),
  desconto        DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
  frete           DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (frete >= 0),
  CONSTRAINT fk_pedido_pessoa FOREIGN KEY (pessoa_id) REFERENCES pessoas(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_pedidos_data (data_pedido)
) ENGINE=InnoDB;

CREATE TABLE itens_pedido (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id      INT NOT NULL,
  obra_id        INT NOT NULL,
  quantidade     INT NOT NULL DEFAULT 1 CHECK (quantidade > 0),
  preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
  CONSTRAINT uq_item UNIQUE (pedido_id, obra_id),
  CONSTRAINT fk_item_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_item_obra   FOREIGN KEY (obra_id)   REFERENCES obras(id)   ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE emprestimos (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  exemplar_id    INT  NOT NULL,
  pessoa_id      INT  NOT NULL,
  data_retirada  DATE NOT NULL DEFAULT (CURRENT_DATE),
  data_prevista  DATE NOT NULL,
  data_devolucao DATE NULL,
  renovacoes     TINYINT NOT NULL DEFAULT 0 CHECK (renovacoes <= 3),
  multa          DECIMAL(8,2) NOT NULL DEFAULT 0 CHECK (multa >= 0),
  multa_paga     TINYINT(1) NOT NULL DEFAULT 0,
  observacao     VARCHAR(200),
  em_aberto      TINYINT(1) AS (IF(data_devolucao IS NULL, 1, NULL)) STORED,
  CONSTRAINT uq_exemplar_aberto UNIQUE (exemplar_id, em_aberto),
  CONSTRAINT ck_datas CHECK (data_prevista >= data_retirada AND (data_devolucao IS NULL OR data_devolucao >= data_retirada)),
  CONSTRAINT fk_emp_exemplar FOREIGN KEY (exemplar_id) REFERENCES exemplares(id) ON DELETE RESTRICT,
  CONSTRAINT fk_emp_pessoa   FOREIGN KEY (pessoa_id)   REFERENCES pessoas(id)    ON DELETE RESTRICT,
  INDEX idx_emp_pessoa (pessoa_id),
  INDEX idx_emp_prevista (data_prevista)
) ENGINE=InnoDB;


  
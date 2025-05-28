-- --------------------------------------------------------
-- Esquema de Banco de Dados Otimizado para MySQL
-- Implementação prática das otimizações documentadas
-- --------------------------------------------------------

-- Remover tabelas caso existam para evitar conflitos
DROP TABLE IF EXISTS itens_venda;
DROP TABLE IF EXISTS vendas_2023_q2;
DROP TABLE IF EXISTS vendas_2023_q1;
DROP TABLE IF EXISTS vendas;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;

-- --------------------------------------------------------
-- Criação das tabelas com estrutura otimizada
-- --------------------------------------------------------

-- Tabela para categorias de produtos
CREATE TABLE categorias (
    id INT NOT NULL AUTO_INCREMENT,
    categoria VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY (categoria)
) ENGINE=InnoDB;

-- Tabela de clientes com segmentação para consultas direcionadas
CREATE TABLE clientes (
    id INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    telefone VARCHAR(20),
    segmento ENUM('REGULAR', 'PREMIUM', 'VIP') DEFAULT 'REGULAR',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_compra DATE,
    PRIMARY KEY (id),
    INDEX (segmento),
    INDEX (ultima_compra)
) ENGINE=InnoDB;

-- Tabela de produtos com categorização
CREATE TABLE produtos (
    id INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(200) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INT NOT NULL DEFAULT 0,
    categoria_id INT NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT check_preco_positivo CHECK (preco > 0),
    CONSTRAINT check_estoque_positivo CHECK (estoque >= 0),
    CONSTRAINT fk_produto_categoria FOREIGN KEY (categoria_id) 
        REFERENCES categorias(id) ON DELETE RESTRICT,
    INDEX idx_produtos_categoria (categoria_id),
    INDEX idx_produtos_categoria_preco (categoria_id, preco DESC)
) ENGINE=InnoDB;

-- Tabela principal de vendas com particionamento por data
-- Nota: No MySQL 8.0+ é possível usar particionamento nativo
CREATE TABLE vendas (
    id INT NOT NULL AUTO_INCREMENT,
    data_venda DATE NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    cliente_id INT NOT NULL,
    status ENUM('PENDENTE', 'PAGO', 'CANCELADO', 'ENVIADO', 'CONCLUIDO') DEFAULT 'PENDENTE',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, data_venda),
    CONSTRAINT fk_vendas_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE RESTRICT,
    INDEX idx_vendas_cliente (cliente_id),
    INDEX idx_vendas_data (data_venda),
    INDEX idx_vendas_cliente_data (cliente_id, data_venda),
    INDEX idx_vendas_status (status)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(data_venda)) (
    PARTITION vendas_2023_q1 VALUES LESS THAN (TO_DAYS('2023-04-01')),
    PARTITION vendas_2023_q2 VALUES LESS THAN (TO_DAYS('2023-07-01')),
    PARTITION vendas_2023_q3 VALUES LESS THAN (TO_DAYS('2023-10-01')),
    PARTITION vendas_2023_q4 VALUES LESS THAN (TO_DAYS('2024-01-01')),
    PARTITION vendas_future VALUES LESS THAN MAXVALUE
);

-- Tabela de itens de venda separada para otimização de consultas
CREATE TABLE itens_venda (
    id INT NOT NULL AUTO_INCREMENT,
    venda_id INT NOT NULL,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL,
    valor_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (quantidade * valor_unitario) STORED,
    PRIMARY KEY (id),
    CONSTRAINT fk_item_venda FOREIGN KEY (venda_id) 
        REFERENCES vendas(id) ON DELETE CASCADE,
    CONSTRAINT fk_item_produto FOREIGN KEY (produto_id) 
        REFERENCES produtos(id) ON DELETE RESTRICT,
    CONSTRAINT check_quantidade_positiva CHECK (quantidade > 0),
    INDEX idx_itens_venda (venda_id),
    INDEX idx_itens_venda_produto (produto_id, venda_id)
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- Triggers para manter a integridade e otimizar operações
-- --------------------------------------------------------

-- Trigger para atualizar o valor total da venda ao inserir um item
DELIMITER //
CREATE TRIGGER tgr_itens_venda_after_insert 
AFTER INSERT ON itens_venda
FOR EACH ROW
BEGIN
    UPDATE vendas 
    SET valor_total = valor_total + NEW.subtotal
    WHERE id = NEW.venda_id;
END//

-- Trigger para atualizar o valor total da venda ao atualizar um item
CREATE TRIGGER tgr_itens_venda_after_update
AFTER UPDATE ON itens_venda
FOR EACH ROW
BEGIN
    UPDATE vendas 
    SET valor_total = valor_total - OLD.subtotal + NEW.subtotal
    WHERE id = NEW.venda_id;
END//

-- Trigger para atualizar o valor total da venda ao remover um item
CREATE TRIGGER tgr_itens_venda_after_delete
AFTER DELETE ON itens_venda
FOR EACH ROW
BEGIN
    UPDATE vendas 
    SET valor_total = valor_total - OLD.subtotal
    WHERE id = OLD.venda_id;
END//

-- Trigger para atualizar a data da última compra do cliente
CREATE TRIGGER tgr_vendas_after_insert
AFTER INSERT ON vendas
FOR EACH ROW
BEGIN
    UPDATE clientes
    SET ultima_compra = NEW.data_venda
    WHERE id = NEW.cliente_id AND (ultima_compra IS NULL OR NEW.data_venda > ultima_compra);
END//

DELIMITER ;

-- --------------------------------------------------------
-- Comentários sobre as otimizações implementadas
-- --------------------------------------------------------

/*
Otimizações implementadas:

1. Particionamento da tabela de vendas por período
   - Melhora performance em consultas por período
   - Facilita manutenção e expurgo de dados antigos

2. Índices estratégicos
   - Índices simples para colunas frequentemente filtradas
   - Índices compostos para otimizar JOINs e ordenações
   - Evitamos excesso de índices para não comprometer escrita

3. Campos calculados
   - Subtotal pré-calculado em itens_venda
   - Reduz cálculos repetitivos em consultas

4. Triggers para manter consistência
   - Atualização automática de valor_total na tabela vendas
   - Atualização da última compra do cliente
   - Evita JOINs e cálculos em consultas frequentes

5. Normalização estratégica
   - Separação de itens_venda da tabela vendas
   - Adição de campos de segmentação para consultas direcionadas
*/ 
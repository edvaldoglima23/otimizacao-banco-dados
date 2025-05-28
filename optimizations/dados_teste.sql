-- --------------------------------------------------------
-- Script para Geração de Dados de Teste (10.550+ registros)
-- Útil para demonstrar as otimizações em ambiente de teste
-- --------------------------------------------------------

-- --------------------------------------------------------
-- Limpeza das tabelas existentes
-- --------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE itens_venda;
TRUNCATE TABLE vendas;
TRUNCATE TABLE produtos;
TRUNCATE TABLE clientes;
TRUNCATE TABLE categorias;
SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------------------------------------
-- 1. Inserção de Categorias
-- --------------------------------------------------------
INSERT INTO categorias (categoria, descricao, ativo) VALUES
('Eletrônicos', 'Produtos eletrônicos em geral', 1),
('Informática', 'Equipamentos e acessórios de informática', 1),
('Móveis', 'Móveis para casa e escritório', 1),
('Eletrodomésticos', 'Eletrodomésticos para casa', 1),
('Celulares', 'Smartphones e acessórios', 1),
('Livros', 'Livros físicos e digitais', 1),
('Games', 'Jogos e consoles', 1),
('Moda', 'Roupas e acessórios', 1),
('Esportes', 'Artigos esportivos', 1),
('Saúde', 'Produtos de saúde e bem-estar', 1);

-- --------------------------------------------------------
-- 2. Inserção de Clientes (500 registros)
-- --------------------------------------------------------
DELIMITER //
CREATE PROCEDURE gerar_clientes()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE segmento_cliente VARCHAR(10);
  
  WHILE i < 500 DO
    -- Determina o segmento com base em uma distribuição realista
    SET segmento_cliente = CASE 
        WHEN i % 10 = 0 THEN 'VIP'
        WHEN i % 5 = 0 THEN 'PREMIUM'
        ELSE 'REGULAR'
    END;
    
    INSERT INTO clientes (nome, email, telefone, segmento, criado_em)
    VALUES (
        CONCAT('Cliente ', i),
        CONCAT('cliente', i, '@email.com'),
        CONCAT('(', FLOOR(RAND() * 90) + 10, ') 9', FLOOR(RAND() * 9000) + 1000, '-', FLOOR(RAND() * 9000) + 1000),
        segmento_cliente,
        DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 365) DAY)
    );
    
    SET i = i + 1;
  END WHILE;
END//
DELIMITER ;

-- Executa o procedimento para gerar clientes
CALL gerar_clientes();
DROP PROCEDURE gerar_clientes;

-- --------------------------------------------------------
-- 3. Inserção de Produtos (200 registros por categoria = 2.000 total)
-- --------------------------------------------------------
DELIMITER //
CREATE PROCEDURE gerar_produtos()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE cat_id INT;
  DECLARE cat_count INT;
  
  -- Obtém o número de categorias
  SELECT COUNT(*) INTO cat_count FROM categorias;
  
  WHILE i < (200 * cat_count) DO
    -- Determina a categoria deste produto
    SET cat_id = (i % cat_count) + 1;
    
    INSERT INTO produtos (nome, preco, estoque, categoria_id, ativo, criado_em)
    VALUES (
        CONCAT('Produto ', i, ' - Cat ', cat_id),
        ROUND(RAND() * 1000 + 50, 2), -- Preço entre 50 e 1050
        FLOOR(RAND() * 100) + 10, -- Estoque entre 10 e 110
        cat_id,
        CASE WHEN RAND() > 0.05 THEN 1 ELSE 0 END, -- 95% dos produtos ativos
        DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 365) DAY)
    );
    
    SET i = i + 1;
  END WHILE;
END//
DELIMITER ;

-- Executa o procedimento para gerar produtos
CALL gerar_produtos();
DROP PROCEDURE gerar_produtos;

-- --------------------------------------------------------
-- 4. Inserção de Vendas e Itens (8.050 vendas com média de 3 itens = ~24.150 itens)
-- --------------------------------------------------------
DELIMITER //
CREATE PROCEDURE gerar_vendas()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE j INT;
  DECLARE venda_id INT;
  DECLARE cliente_id INT;
  DECLARE produto_id INT;
  DECLARE qtd_itens INT;
  DECLARE preco_produto DECIMAL(10,2);
  DECLARE quantidade INT;
  DECLARE data_venda DATE;
  DECLARE status_venda VARCHAR(20);
  DECLARE total_clientes INT;
  DECLARE total_produtos INT;
  
  -- Obtém o total de clientes e produtos
  SELECT COUNT(*) INTO total_clientes FROM clientes;
  SELECT COUNT(*) INTO total_produtos FROM produtos;
  
  -- Gerar 8.050 vendas
  WHILE i < 8050 DO
    -- Seleciona um cliente aleatório
    SET cliente_id = FLOOR(RAND() * total_clientes) + 1;
    
    -- Define a data da venda (últimos 2 anos)
    SET data_venda = DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 730) DAY);
    
    -- Define o status da venda
    SET status_venda = ELT(FLOOR(RAND() * 5) + 1, 'PENDENTE', 'PAGO', 'CANCELADO', 'ENVIADO', 'CONCLUIDO');
    
    -- Insere a venda
    INSERT INTO vendas (data_venda, valor_total, cliente_id, status, criado_em)
    VALUES (data_venda, 0, cliente_id, status_venda, data_venda);
    
    -- Obtém o ID da venda inserida
    SET venda_id = LAST_INSERT_ID();
    
    -- Define quantos itens esta venda terá (entre 1 e 5)
    SET qtd_itens = FLOOR(RAND() * 5) + 1;
    SET j = 0;
    
    -- Insere os itens da venda
    WHILE j < qtd_itens DO
      -- Seleciona um produto aleatório
      SET produto_id = FLOOR(RAND() * total_produtos) + 1;
      
      -- Obtém o preço do produto
      SELECT preco INTO preco_produto FROM produtos WHERE id = produto_id;
      
      -- Define a quantidade
      SET quantidade = FLOOR(RAND() * 5) + 1;
      
      -- Insere o item
      INSERT INTO itens_venda (venda_id, produto_id, quantidade, valor_unitario)
      VALUES (venda_id, produto_id, quantidade, preco_produto);
      
      SET j = j + 1;
    END WHILE;
    
    SET i = i + 1;
  END WHILE;
END//
DELIMITER ;

-- Executa o procedimento para gerar vendas
CALL gerar_vendas();
DROP PROCEDURE gerar_vendas;

-- --------------------------------------------------------
-- 5. Atualização de estatísticas após inserções
-- --------------------------------------------------------
ANALYZE TABLE categorias, clientes, produtos, vendas, itens_venda;

-- --------------------------------------------------------
-- 6. Verificação dos dados gerados
-- --------------------------------------------------------
SELECT 'Categorias' as tabela, COUNT(*) as registros FROM categorias
UNION ALL
SELECT 'Clientes', COUNT(*) FROM clientes
UNION ALL
SELECT 'Produtos', COUNT(*) FROM produtos
UNION ALL
SELECT 'Vendas', COUNT(*) FROM vendas
UNION ALL
SELECT 'Itens de Venda', COUNT(*) FROM itens_venda;

/*
Resultado esperado:

+---------------+------------+
| tabela        | registros  |
+---------------+------------+
| Categorias    | 10         |
| Clientes      | 500        |
| Produtos      | 2,000      |
| Vendas        | 8,050      |
| Itens de Venda| ~24,150    |
+---------------+------------+

Total: ~34,710 registros no banco
*/ 
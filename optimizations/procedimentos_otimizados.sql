-- --------------------------------------------------------
-- Procedimentos Armazenados Otimizados para MySQL
-- --------------------------------------------------------

-- --------------------------------------------------------
-- 1. Relatório de Vendas por Período
-- --------------------------------------------------------
DELIMITER //

CREATE PROCEDURE sp_relatorio_vendas_periodo (
    IN data_inicio DATE,
    IN data_fim DATE
)
BEGIN
    -- Utiliza tabela temporária para melhorar performance
    -- Evita múltiplas leituras da tabela de vendas
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_vendas_periodo AS
    SELECT 
        DATE_FORMAT(data_venda, '%Y-%m-%d') as data,
        COUNT(*) as total_vendas,
        SUM(valor_total) as valor_total
    FROM vendas
    WHERE data_venda BETWEEN data_inicio AND data_fim
      AND status != 'CANCELADO'
    GROUP BY DATE_FORMAT(data_venda, '%Y-%m-%d');
    
    -- Retorna os resultados otimizados
    SELECT 
        data,
        total_vendas,
        valor_total,
        (SELECT AVG(valor_total) FROM temp_vendas_periodo) as media_diaria,
        valor_total / total_vendas as ticket_medio
    FROM temp_vendas_periodo
    ORDER BY data;
    
    -- Limpa tabela temporária
    DROP TEMPORARY TABLE IF EXISTS temp_vendas_periodo;
END//

-- --------------------------------------------------------
-- 2. Busca de Produtos com Filtros Otimizada
-- --------------------------------------------------------
CREATE PROCEDURE sp_busca_produtos (
    IN p_categoria_id INT,
    IN p_preco_min DECIMAL(10,2),
    IN p_preco_max DECIMAL(10,2),
    IN p_ordenacao VARCHAR(20),
    IN p_limit INT
)
BEGIN
    -- Variáveis para construção dinâmica da query
    DECLARE where_clause VARCHAR(255) DEFAULT '';
    DECLARE order_clause VARCHAR(100);
    
    -- Construção do WHERE dinâmico
    IF p_categoria_id IS NOT NULL THEN
        SET where_clause = CONCAT(' AND p.categoria_id = ', p_categoria_id);
    END IF;
    
    IF p_preco_min IS NOT NULL THEN
        SET where_clause = CONCAT(where_clause, ' AND p.preco >= ', p_preco_min);
    END IF;
    
    IF p_preco_max IS NOT NULL THEN
        SET where_clause = CONCAT(where_clause, ' AND p.preco <= ', p_preco_max);
    END IF;
    
    -- Definição da ordenação
    CASE p_ordenacao
        WHEN 'preco_asc' THEN SET order_clause = 'p.preco ASC';
        WHEN 'preco_desc' THEN SET order_clause = 'p.preco DESC';
        WHEN 'nome' THEN SET order_clause = 'p.nome ASC';
        WHEN 'mais_vendidos' THEN SET order_clause = 'vendas DESC';
        ELSE SET order_clause = 'p.id ASC';
    END CASE;
    
    -- Define limite padrão se não informado
    IF p_limit IS NULL THEN
        SET p_limit = 100;
    END IF;
    
    -- Executa a consulta otimizada com a ordenação apropriada
    SET @sql = CONCAT('
        SELECT 
            p.id,
            p.nome,
            p.preco,
            p.estoque,
            c.categoria,
            (SELECT COUNT(*) FROM itens_venda iv WHERE iv.produto_id = p.id) as vendas
        FROM produtos p
        JOIN categorias c ON p.categoria_id = c.id
        WHERE p.ativo = 1 ', where_clause, '
        ORDER BY ', order_clause, '
        LIMIT ', p_limit);
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END//

-- --------------------------------------------------------
-- 3. Atualização de Estoque com Transação Otimizada
-- --------------------------------------------------------
CREATE PROCEDURE sp_atualiza_estoque (
    IN p_produto_id INT,
    IN p_quantidade INT,
    IN p_operacao CHAR(1) -- 'A' para adicionar, 'R' para remover
)
BEGIN
    DECLARE atual_estoque INT;
    DECLARE exit handler for sqlexception
    BEGIN
        -- Tratamento de erro
        ROLLBACK;
        SELECT 'Erro ao atualizar estoque' as mensagem;
    END;
    
    -- Inicia transação para garantir consistência
    START TRANSACTION;
    
    -- Seleciona com bloqueio para evitar concorrência
    SELECT estoque INTO atual_estoque 
    FROM produtos 
    WHERE id = p_produto_id 
    FOR UPDATE;
    
    -- Valida se o produto existe
    IF atual_estoque IS NULL THEN
        ROLLBACK;
        SELECT 'Produto não encontrado' as mensagem;
    ELSE
        -- Atualiza o estoque com base na operação
        IF p_operacao = 'A' THEN
            UPDATE produtos 
            SET estoque = estoque + p_quantidade 
            WHERE id = p_produto_id;
            
            SELECT 'Estoque adicionado com sucesso' as mensagem;
        ELSEIF p_operacao = 'R' THEN
            -- Verifica se há estoque suficiente
            IF atual_estoque >= p_quantidade THEN
                UPDATE produtos 
                SET estoque = estoque - p_quantidade 
                WHERE id = p_produto_id;
                
                SELECT 'Estoque removido com sucesso' as mensagem;
            ELSE
                ROLLBACK;
                SELECT 'Estoque insuficiente' as mensagem;
            END IF;
        ELSE
            ROLLBACK;
            SELECT 'Operação inválida' as mensagem;
        END IF;
    END IF;
    
    -- Confirma a transação
    COMMIT;
END//

-- --------------------------------------------------------
-- 4. Dashboard de Performance de Vendas
-- --------------------------------------------------------
CREATE PROCEDURE sp_dashboard_vendas()
BEGIN
    -- Vendas por período (últimos 12 meses)
    WITH vendas_mensais AS (
        SELECT 
            DATE_FORMAT(data_venda, '%Y-%m') as periodo,
            COUNT(*) as total_vendas,
            SUM(valor_total) as valor_total
        FROM vendas
        WHERE data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
          AND status != 'CANCELADO'
        GROUP BY DATE_FORMAT(data_venda, '%Y-%m')
    )
    
    SELECT 
        'vendas_mensais' as tipo_relatorio,
        periodo,
        total_vendas,
        valor_total,
        NULL as nome,
        NULL as categoria
    FROM vendas_mensais
    
    UNION ALL
    
    -- Top 10 produtos mais vendidos
    SELECT 
        'produtos_top' as tipo_relatorio,
        NULL as periodo,
        SUM(iv.quantidade) as total_vendas,
        SUM(iv.subtotal) as valor_total,
        p.nome,
        c.categoria
    FROM itens_venda iv
    JOIN produtos p ON iv.produto_id = p.id
    JOIN categorias c ON p.categoria_id = c.id
    JOIN vendas v ON iv.venda_id = v.id
    WHERE v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
      AND v.status != 'CANCELADO'
    GROUP BY p.id, p.nome, c.categoria
    ORDER BY total_vendas DESC
    LIMIT 10
    
    UNION ALL
    
    -- Top 5 categorias
    SELECT 
        'categorias_top' as tipo_relatorio,
        NULL as periodo,
        COUNT(DISTINCT v.id) as total_vendas,
        SUM(v.valor_total) as valor_total,
        NULL as nome,
        c.categoria
    FROM vendas v
    JOIN itens_venda iv ON v.id = iv.venda_id
    JOIN produtos p ON iv.produto_id = p.id
    JOIN categorias c ON p.categoria_id = c.id
    WHERE v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
      AND v.status != 'CANCELADO'
    GROUP BY c.id, c.categoria
    ORDER BY valor_total DESC
    LIMIT 5;
END//

-- --------------------------------------------------------
-- 5. Manutenção de Banco Otimizada
-- --------------------------------------------------------
CREATE PROCEDURE sp_manutencao_banco()
BEGIN
    -- Atualiza estatísticas de tabelas para o otimizador
    ANALYZE TABLE categorias, clientes, produtos, vendas, itens_venda;
    
    -- Otimiza as tabelas (reorganiza índices e dados)
    OPTIMIZE TABLE categorias, clientes, produtos, vendas, itens_venda;
    
    -- Identifica e registra índices não utilizados
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_indices_nao_utilizados AS
    SELECT 
        table_schema as banco,
        table_name as tabela,
        index_name as indice
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND index_name != 'PRIMARY'
      AND (table_name, index_name) NOT IN (
          SELECT object_name, index_name
          FROM performance_schema.table_io_waits_summary_by_index_usage
          WHERE index_name IS NOT NULL
            AND count_star > 0
      );
    
    -- Retorna resultados da manutenção
    SELECT 'Manutenção concluída com sucesso' as mensagem;
    
    -- Lista índices candidatos à remoção
    SELECT * FROM temp_indices_nao_utilizados;
    
    -- Limpa tabela temporária
    DROP TEMPORARY TABLE IF EXISTS temp_indices_nao_utilizados;
END//

DELIMITER ; 
-- --------------------------------------------------------
-- Benchmark de Otimizações SQL
-- Comparação de performance antes e depois
-- --------------------------------------------------------

-- --------------------------------------------------------
-- Configurações Iniciais
-- --------------------------------------------------------

-- Habilitar profiling para medir performance
SET profiling = 1;
SET profiling_history_size = 100;

-- Tabela para armazenar resultados de benchmark
DROP TABLE IF EXISTS benchmark_resultados;
CREATE TABLE benchmark_resultados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(200) NOT NULL,
    versao VARCHAR(20) NOT NULL,
    tempo_execucao DECIMAL(10,6) NOT NULL,
    linhas_afetadas INT,
    momento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Procedure para executar e registrar benchmark
DELIMITER //
CREATE PROCEDURE benchmark_consulta(
    IN p_descricao VARCHAR(200),
    IN p_consulta_original TEXT,
    IN p_consulta_otimizada TEXT
)
BEGIN
    DECLARE tempo_original DECIMAL(10,6);
    DECLARE tempo_otimizado DECIMAL(10,6);
    DECLARE linhas_original INT;
    DECLARE linhas_otimizado INT;
    
    -- Limpar cache de consultas para teste justo
    RESET QUERY CACHE;
    FLUSH TABLES;
    
    -- Executar consulta original
    SET @start = NOW(6);
    SET @sql = p_consulta_original;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    SET linhas_original = ROW_COUNT();
    DEALLOCATE PREPARE stmt;
    SET tempo_original = TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) / 1000000;
    
    -- Registrar resultado original
    INSERT INTO benchmark_resultados (descricao, versao, tempo_execucao, linhas_afetadas)
    VALUES (p_descricao, 'ORIGINAL', tempo_original, linhas_original);
    
    -- Limpar cache novamente
    RESET QUERY CACHE;
    FLUSH TABLES;
    
    -- Executar consulta otimizada
    SET @start = NOW(6);
    SET @sql = p_consulta_otimizada;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    SET linhas_otimizado = ROW_COUNT();
    DEALLOCATE PREPARE stmt;
    SET tempo_otimizado = TIMESTAMPDIFF(MICROSECOND, @start, NOW(6)) / 1000000;
    
    -- Registrar resultado otimizado
    INSERT INTO benchmark_resultados (descricao, versao, tempo_execucao, linhas_afetadas)
    VALUES (p_descricao, 'OTIMIZADA', tempo_otimizado, linhas_otimizado);
    
    -- Calcular e mostrar a melhoria
    SELECT 
        p_descricao as teste,
        tempo_original as tempo_original_s,
        tempo_otimizado as tempo_otimizado_s,
        (tempo_original - tempo_otimizado) as reducao_tempo_s,
        ROUND(((tempo_original - tempo_otimizado) / tempo_original) * 100, 2) as melhoria_percentual;
END//
DELIMITER ;

-- --------------------------------------------------------
-- Benchmark 1: Relatório de Vendas por Cliente
-- --------------------------------------------------------
CALL benchmark_consulta(
    'Relatório de Vendas por Cliente',
    'SELECT 
        c.nome,
        COUNT(v.id) as total_pedidos,
        SUM(v.valor_total) as valor_total
     FROM vendas v
     JOIN clientes c ON v.cliente_id = c.id
     WHERE v.data_venda BETWEEN "2023-01-01" AND "2023-12-31"
     GROUP BY c.nome
     ORDER BY valor_total DESC',
    'SELECT 
        c.nome,
        COUNT(v.id) as total_pedidos,
        SUM(v.valor_total) as valor_total
     FROM vendas v
     JOIN clientes c ON v.cliente_id = c.id
     WHERE v.data_venda BETWEEN "2023-01-01" AND "2023-12-31"
       AND c.segmento = "PREMIUM"
     GROUP BY c.id, c.nome
     ORDER BY valor_total DESC
     LIMIT 100'
);

-- --------------------------------------------------------
-- Benchmark 2: Produtos Mais Vendidos
-- --------------------------------------------------------
CALL benchmark_consulta(
    'Produtos Mais Vendidos',
    'SELECT 
        p.nome as produto,
        cat.categoria,
        SUM(iv.quantidade) as quantidade_vendida,
        SUM(iv.quantidade * iv.valor_unitario) as valor_total
     FROM itens_venda iv
     JOIN produtos p ON iv.produto_id = p.id
     JOIN categorias cat ON p.categoria_id = cat.id
     JOIN vendas v ON iv.venda_id = v.id
     WHERE v.data_venda BETWEEN "2023-01-01" AND "2023-12-31"
     GROUP BY p.nome, cat.categoria
     ORDER BY quantidade_vendida DESC',
    'WITH vendas_periodo AS (
        SELECT id
        FROM vendas
        WHERE data_venda BETWEEN "2023-01-01" AND "2023-12-31"
          AND status = "CONCLUIDO"
     )
     SELECT 
        p.nome as produto,
        cat.categoria,
        SUM(iv.quantidade) as quantidade_vendida,
        SUM(iv.subtotal) as valor_total
     FROM itens_venda iv
     JOIN vendas_periodo vp ON iv.venda_id = vp.id
     JOIN produtos p ON iv.produto_id = p.id
     JOIN categorias cat ON p.categoria_id = cat.id
     GROUP BY p.id, p.nome, cat.categoria
     ORDER BY quantidade_vendida DESC
     LIMIT 100'
);

-- --------------------------------------------------------
-- Benchmark 3: Análise de Vendas por Período
-- --------------------------------------------------------
CALL benchmark_consulta(
    'Análise de Vendas por Período',
    'SELECT 
        DATE_FORMAT(v.data_venda, "%Y-%m") as periodo,
        COUNT(DISTINCT v.id) as total_vendas,
        COUNT(DISTINCT v.cliente_id) as total_clientes,
        SUM(v.valor_total) as valor_total
     FROM vendas v
     WHERE v.data_venda >= "2023-01-01"
     GROUP BY DATE_FORMAT(v.data_venda, "%Y-%m")
     ORDER BY periodo',
    'SELECT 
        CONCAT(EXTRACT(YEAR FROM v.data_venda), "-", LPAD(EXTRACT(MONTH FROM v.data_venda), 2, "0")) as periodo,
        COUNT(DISTINCT v.id) as total_vendas,
        COUNT(DISTINCT v.cliente_id) as total_clientes,
        SUM(v.valor_total) as valor_total
     FROM vendas v
     WHERE v.data_venda >= "2023-01-01"
       AND v.status IN ("PAGO", "CONCLUIDO")
     GROUP BY EXTRACT(YEAR FROM v.data_venda), EXTRACT(MONTH FROM v.data_venda)
     ORDER BY periodo'
);

-- --------------------------------------------------------
-- Benchmark 4: Análise de Clientes
-- --------------------------------------------------------
CALL benchmark_consulta(
    'Análise de Clientes',
    'SELECT 
        c.nome,
        c.email,
        (SELECT COUNT(*) FROM vendas WHERE cliente_id = c.id) as total_compras,
        (SELECT MAX(data_venda) FROM vendas WHERE cliente_id = c.id) as ultima_compra,
        (SELECT SUM(valor_total) FROM vendas WHERE cliente_id = c.id) as valor_total_gasto
     FROM clientes c
     WHERE (SELECT COUNT(*) FROM vendas WHERE cliente_id = c.id) > 0
     ORDER BY valor_total_gasto DESC',
    'SELECT 
        c.nome,
        c.email,
        c.segmento,
        COUNT(v.id) as total_compras,
        c.ultima_compra,
        SUM(v.valor_total) as valor_total_gasto,
        AVG(v.valor_total) as ticket_medio
     FROM clientes c
     JOIN vendas v ON c.id = v.cliente_id
     WHERE v.status != "CANCELADO"
     GROUP BY c.id, c.nome, c.email, c.segmento, c.ultima_compra
     HAVING COUNT(v.id) > 0
     ORDER BY valor_total_gasto DESC
     LIMIT 100'
);

-- --------------------------------------------------------
-- Benchmark 5: Análise de Estoque
-- --------------------------------------------------------
CALL benchmark_consulta(
    'Análise de Estoque',
    'SELECT 
        p.nome,
        p.estoque,
        (SELECT SUM(quantidade) FROM itens_venda WHERE produto_id = p.id) as qtd_vendida,
        (SELECT SUM(quantidade) FROM itens_venda iv JOIN vendas v ON iv.venda_id = v.id 
         WHERE iv.produto_id = p.id AND v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)) as vendas_30_dias,
        p.estoque / NULLIF((SELECT AVG(quantidade) FROM itens_venda iv JOIN vendas v ON iv.venda_id = v.id 
                            WHERE iv.produto_id = p.id AND v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)), 0) as dias_estoque
     FROM produtos p
     WHERE p.ativo = 1
     ORDER BY dias_estoque',
    'WITH vendas_totais AS (
        SELECT 
            iv.produto_id,
            SUM(iv.quantidade) as qtd_total
        FROM itens_venda iv
        GROUP BY iv.produto_id
    ),
    vendas_recentes AS (
        SELECT 
            iv.produto_id,
            SUM(iv.quantidade) as qtd_30_dias,
            AVG(iv.quantidade) as media_diaria
        FROM itens_venda iv
        JOIN vendas v ON iv.venda_id = v.id
        WHERE v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
          AND v.status != "CANCELADO"
        GROUP BY iv.produto_id
    )
    SELECT 
        p.nome,
        cat.categoria,
        p.estoque,
        COALESCE(vt.qtd_total, 0) as qtd_vendida,
        COALESCE(vr.qtd_30_dias, 0) as vendas_30_dias,
        CASE 
            WHEN vr.media_diaria > 0 THEN ROUND(p.estoque / vr.media_diaria)
            ELSE NULL
        END as dias_estoque
    FROM produtos p
    JOIN categorias cat ON p.categoria_id = cat.id
    LEFT JOIN vendas_totais vt ON p.id = vt.produto_id
    LEFT JOIN vendas_recentes vr ON p.id = vr.produto_id
    WHERE p.ativo = 1
    ORDER BY 
        CASE WHEN vr.media_diaria > 0 THEN p.estoque / vr.media_diaria ELSE 999999 END
    LIMIT 100'
);

-- --------------------------------------------------------
-- Relatório Final de Performance
-- --------------------------------------------------------
SELECT 
    descricao as teste,
    versao,
    ROUND(tempo_execucao, 4) as tempo_execucao_s,
    linhas_afetadas
FROM 
    benchmark_resultados
ORDER BY 
    descricao, versao;

-- Análise comparativa de melhorias
SELECT 
    t1.descricao as teste,
    ROUND(t1.tempo_execucao, 4) as tempo_original_s,
    ROUND(t2.tempo_execucao, 4) as tempo_otimizado_s,
    ROUND(t1.tempo_execucao - t2.tempo_execucao, 4) as reducao_tempo_s,
    ROUND(((t1.tempo_execucao - t2.tempo_execucao) / t1.tempo_execucao) * 100, 2) as melhoria_percentual
FROM 
    benchmark_resultados t1
JOIN 
    benchmark_resultados t2 ON t1.descricao = t2.descricao AND t1.versao = 'ORIGINAL' AND t2.versao = 'OTIMIZADA'
ORDER BY 
    melhoria_percentual DESC;

-- Limpar recursos
DROP PROCEDURE benchmark_consulta;
SET profiling = 0; 
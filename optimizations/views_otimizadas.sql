-- --------------------------------------------------------
-- Views Otimizadas para MySQL
-- Implementação de views para performance e reutilização
-- --------------------------------------------------------

-- --------------------------------------------------------
-- 1. View para Produto com Dados de Categoria e Estatísticas
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_produtos_completo AS
SELECT 
    p.id,
    p.nome,
    p.preco,
    p.estoque,
    p.ativo,
    c.id as categoria_id,
    c.categoria,
    COALESCE((SELECT SUM(iv.quantidade) FROM itens_venda iv WHERE iv.produto_id = p.id), 0) as total_vendido,
    CASE 
        WHEN p.estoque > 0 AND COALESCE((SELECT AVG(iv.quantidade) 
                              FROM itens_venda iv 
                              JOIN vendas v ON iv.venda_id = v.id 
                              WHERE iv.produto_id = p.id AND v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)), 0) > 0 
        THEN ROUND(p.estoque / (SELECT AVG(iv.quantidade) 
                              FROM itens_venda iv 
                              JOIN vendas v ON iv.venda_id = v.id 
                              WHERE iv.produto_id = p.id AND v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)))
        ELSE NULL
    END as dias_estoque
FROM 
    produtos p
JOIN 
    categorias c ON p.categoria_id = c.id;

-- --------------------------------------------------------
-- 2. View para Dashboard de Vendas por Período
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_vendas_por_periodo AS
SELECT 
    DATE_FORMAT(v.data_venda, '%Y-%m') as periodo,
    COUNT(*) as total_vendas,
    COUNT(DISTINCT v.cliente_id) as total_clientes,
    SUM(v.valor_total) as valor_total,
    AVG(v.valor_total) as ticket_medio,
    COALESCE(LAG(SUM(v.valor_total)) OVER (ORDER BY DATE_FORMAT(v.data_venda, '%Y-%m')), 0) as valor_periodo_anterior,
    CASE 
        WHEN LAG(SUM(v.valor_total)) OVER (ORDER BY DATE_FORMAT(v.data_venda, '%Y-%m')) > 0
        THEN ROUND(((SUM(v.valor_total) - LAG(SUM(v.valor_total)) OVER (ORDER BY DATE_FORMAT(v.data_venda, '%Y-%m'))) / 
                    LAG(SUM(v.valor_total)) OVER (ORDER BY DATE_FORMAT(v.data_venda, '%Y-%m'))) * 100, 2)
        ELSE NULL
    END as percentual_crescimento
FROM 
    vendas v
WHERE 
    v.status != 'CANCELADO'
    AND v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
GROUP BY 
    DATE_FORMAT(v.data_venda, '%Y-%m')
ORDER BY 
    periodo;

-- --------------------------------------------------------
-- 3. View para Análise de Clientes e Segmentação
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_clientes_segmentacao AS
SELECT 
    c.id,
    c.nome,
    c.email,
    c.segmento,
    c.ultima_compra,
    DATEDIFF(CURRENT_DATE, c.ultima_compra) as dias_desde_ultima_compra,
    COUNT(v.id) as total_compras,
    SUM(v.valor_total) as valor_total_gasto,
    AVG(v.valor_total) as ticket_medio,
    CASE 
        WHEN COUNT(v.id) >= 10 AND SUM(v.valor_total) >= 5000 THEN 'PREMIUM'
        WHEN COUNT(v.id) >= 5 AND SUM(v.valor_total) >= 2000 THEN 'FIEL'
        WHEN DATEDIFF(CURRENT_DATE, c.ultima_compra) <= 30 THEN 'ATIVO'
        WHEN DATEDIFF(CURRENT_DATE, c.ultima_compra) <= 90 THEN 'POTENCIAL'
        ELSE 'INATIVO'
    END as segmentacao_recomendada
FROM 
    clientes c
LEFT JOIN 
    vendas v ON c.id = v.cliente_id AND v.status != 'CANCELADO'
GROUP BY 
    c.id, c.nome, c.email, c.segmento, c.ultima_compra;

-- --------------------------------------------------------
-- 4. View para Relatório de Estoque Crítico
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_estoque_critico AS
WITH vendas_recentes AS (
    SELECT 
        iv.produto_id,
        SUM(iv.quantidade) as qtd_vendida_30_dias,
        AVG(iv.quantidade) as media_diaria_venda
    FROM 
        itens_venda iv
    JOIN 
        vendas v ON iv.venda_id = v.id
    WHERE 
        v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
        AND v.status != 'CANCELADO'
    GROUP BY 
        iv.produto_id
)
SELECT 
    p.id,
    p.nome,
    c.categoria,
    p.estoque,
    vr.qtd_vendida_30_dias,
    vr.media_diaria_venda,
    CASE 
        WHEN vr.media_diaria_venda > 0 THEN ROUND(p.estoque / vr.media_diaria_venda)
        ELSE NULL
    END as dias_estoque_restante,
    CASE 
        WHEN p.estoque = 0 THEN 'SEM ESTOQUE'
        WHEN vr.media_diaria_venda > 0 AND ROUND(p.estoque / vr.media_diaria_venda) <= 7 THEN 'CRÍTICO'
        WHEN vr.media_diaria_venda > 0 AND ROUND(p.estoque / vr.media_diaria_venda) <= 15 THEN 'BAIXO'
        WHEN vr.media_diaria_venda > 0 AND ROUND(p.estoque / vr.media_diaria_venda) <= 30 THEN 'MÉDIO'
        ELSE 'ADEQUADO'
    END as status_estoque
FROM 
    produtos p
JOIN 
    categorias c ON p.categoria_id = c.id
LEFT JOIN 
    vendas_recentes vr ON p.id = vr.produto_id
WHERE 
    p.ativo = 1
ORDER BY 
    CASE 
        WHEN p.estoque = 0 THEN 0
        WHEN vr.media_diaria_venda > 0 THEN p.estoque / vr.media_diaria_venda
        ELSE 999999
    END;

-- --------------------------------------------------------
-- 5. View para Análise de Itens Mais Vendidos
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_produtos_mais_vendidos AS
WITH vendas_por_produto AS (
    SELECT 
        iv.produto_id,
        SUM(iv.quantidade) as total_vendido,
        SUM(iv.subtotal) as valor_total_vendido,
        COUNT(DISTINCT iv.venda_id) as total_vendas,
        COUNT(DISTINCT v.cliente_id) as total_clientes
    FROM 
        itens_venda iv
    JOIN 
        vendas v ON iv.venda_id = v.id
    WHERE 
        v.status != 'CANCELADO'
        AND v.data_venda >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY 
        iv.produto_id
)
SELECT 
    p.id,
    p.nome,
    c.categoria,
    p.preco,
    vp.total_vendido,
    vp.valor_total_vendido,
    vp.total_vendas,
    vp.total_clientes,
    ROUND(vp.valor_total_vendido / vp.total_vendido, 2) as preco_medio_venda,
    DENSE_RANK() OVER (ORDER BY vp.total_vendido DESC) as ranking_quantidade,
    DENSE_RANK() OVER (ORDER BY vp.valor_total_vendido DESC) as ranking_valor,
    p.estoque,
    p.estoque * p.preco as valor_estoque
FROM 
    produtos p
JOIN 
    categorias c ON p.categoria_id = c.id
LEFT JOIN 
    vendas_por_produto vp ON p.id = vp.produto_id
WHERE 
    p.ativo = 1
ORDER BY 
    vp.total_vendido DESC NULLS LAST; 
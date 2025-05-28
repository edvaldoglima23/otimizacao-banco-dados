# 🚀 Exemplos de Otimizações de Consultas SQL

## 📊 Caso 1: Otimização de JOIN Complexo

### Consulta Original
```sql
-- Consulta não otimizada
SELECT c.nome, p.produto, v.data_venda, v.valor
FROM clientes c
JOIN vendas v ON c.id = v.cliente_id
JOIN produtos p ON v.produto_id = p.id
WHERE v.data_venda >= '2023-01-01'
ORDER BY v.data_venda DESC;
```

### Consulta Otimizada
```sql
-- Consulta otimizada com índices apropriados
SELECT c.nome, p.produto, v.data_venda, v.valor
FROM vendas v
    INNER JOIN clientes c ON c.id = v.cliente_id
    INNER JOIN produtos p ON v.produto_id = p.id
WHERE v.data_venda >= '2023-01-01'
ORDER BY v.data_venda DESC
LIMIT 1000;
```

### Melhorias Implementadas
- Reordenação das tabelas no JOIN
- Uso de INNER JOIN explícito
- Adição de LIMIT para controle de resultados
- Criação de índices compostos

## 📈 Caso 2: Otimização de Agregações

### Consulta Original
```sql
-- Agregação não otimizada
SELECT 
    c.categoria,
    COUNT(*) as total_vendas,
    SUM(v.valor) as valor_total
FROM vendas v
JOIN produtos p ON v.produto_id = p.id
JOIN categorias c ON p.categoria_id = c.id
GROUP BY c.categoria;
```

### Consulta Otimizada
```sql
-- Agregação otimizada com índices e materialização
WITH vendas_categoria AS (
    SELECT 
        p.categoria_id,
        v.valor
    FROM vendas v
    JOIN produtos p ON v.produto_id = p.id
    WHERE v.status = 'CONCLUIDO'
)
SELECT 
    c.categoria,
    COUNT(*) as total_vendas,
    SUM(vc.valor) as valor_total
FROM vendas_categoria vc
JOIN categorias c ON vc.categoria_id = c.id
GROUP BY c.categoria;
```

### Melhorias Implementadas
- Uso de CTE para materialização
- Redução de JOINs desnecessários
- Filtros aplicados antecipadamente
- Índices otimizados para agregação

## 🔍 Caso 3: Otimização de Subqueries

### Consulta Original
```sql
-- Subquery não otimizada
SELECT p.produto, 
       (SELECT COUNT(*) 
        FROM vendas v 
        WHERE v.produto_id = p.id) as total_vendas
FROM produtos p
WHERE p.ativo = true;
```

### Consulta Otimizada
```sql
-- Substituição por JOIN
SELECT p.produto, 
       COUNT(v.id) as total_vendas
FROM produtos p
LEFT JOIN vendas v ON v.produto_id = p.id
WHERE p.ativo = true
GROUP BY p.id, p.produto;
```

### Melhorias Implementadas
- Substituição de subquery por JOIN
- Uso apropriado de índices
- Melhor utilização do plano de execução 
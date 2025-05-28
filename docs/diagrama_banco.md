# 📊 Diagrama do Banco de Dados Otimizado

## 🔍 Modelo Entidade-Relacionamento (ER)

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│    CATEGORIAS   │      │     PRODUTOS     │      │    CLIENTES     │
├─────────────────┤      ├──────────────────┤      ├─────────────────┤
│ id (PK)         │      │ id (PK)          │      │ id (PK)         │
│ categoria       │◄────┐│ nome             │      │ nome            │
│ descricao       │     └│ categoria_id (FK)│      │ email           │
│ ativo           │      │ preco            │      │ telefone        │
└─────────────────┘      │ estoque          │      │ segmento        │
                         │ ativo            │      │ criado_em       │
                         └──────────────────┘      │ ultima_compra   │
                                 │                 └─────────────────┘
                                 │                         │
                                 │                         │
                                 ▼                         │
                         ┌──────────────────┐             │
                         │   ITENS_VENDA    │             │
                         ├──────────────────┤             │
                         │ id (PK)          │             │
                         │ venda_id (FK)    │◄────────────┘
                         │ produto_id (FK)  │             │
                         │ quantidade       │             │
                         │ valor_unitario   │             │
                         │ subtotal         │             │
                         └──────────────────┘             │
                                 ▲                        │
                                 │                        │
                                 │                        ▼
                         ┌──────────────────┐      ┌─────────────────┐
                         │      VENDAS      │      │  PARTIÇÕES DE   │
                         ├──────────────────┤      │     VENDAS      │
                         │ id (PK)          │      ├─────────────────┤
                         │ data_venda       │      │ vendas_2023_q1  │
                         │ cliente_id (FK)  │      │ vendas_2023_q2  │
                         │ valor_total      │      │ vendas_2023_q3  │
                         │ status           │      │ vendas_2023_q4  │
                         │ criado_em        │      │ vendas_future   │
                         └──────────────────┘      └─────────────────┘
```

## 📈 Organização Física do Banco

```
┌─────────────────────────────────────────────────────────────┐
│                      BANCO DE DADOS                         │
├─────────────┬──────────────┬──────────────┬────────────────┤
│  TABELAS    │    ÍNDICES   │   TRIGGERS   │  PROCEDURES    │
├─────────────┼──────────────┼──────────────┼────────────────┤
│ categorias  │ PRIMARY KEY  │ After Insert │ sp_relatorio   │
│ clientes    │ FOREIGN KEY  │ After Update │ sp_busca       │
│ produtos    │ idx_cliente  │ After Delete │ sp_atualiza    │
│ vendas      │ idx_data     │              │ sp_dashboard   │
│ itens_venda │ idx_produto  │              │ sp_manutencao  │
└─────────────┴──────────────┴──────────────┴────────────────┘
```

## 🔄 Fluxo de Dados e Otimizações

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    ENTRADA      │     │  PROCESSAMENTO  │     │     SAÍDA       │
│    DE DADOS     │────▶│   OTIMIZADO     │────▶│  RÁPIDA E       │
│                 │     │                 │     │  EFICIENTE      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       ▲                       ▲
        │                       │                       │
        ▼                       │                       │
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  VALIDAÇÃO E    │     │   ÍNDICES E     │     │   CONSULTAS     │
│  NORMALIZAÇÃO   │────▶│  PARTICIONAMENTO│────▶│   OTIMIZADAS    │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## 🚀 Arquitetura de Performance

```
NÍVEL DE PERFORMANCE
│
├─── 1. Modelagem Otimizada
│    ├─── Normalização Estratégica
│    ├─── Campos Calculados
│    └─── Relacionamentos Eficientes
│
├─── 2. Estratégia de Índices
│    ├─── Índices Primários
│    ├─── Índices Secundários
│    └─── Índices Compostos
│
├─── 3. Particionamento
│    ├─── Partições por Data
│    └─── Distribuição de Carga
│
├─── 4. Otimização de Consultas
│    ├─── CTEs
│    ├─── JOINs Otimizados
│    └─── Evitar Subqueries
│
└─── 5. Manutenção Contínua
     ├─── Análise de Performance
     ├─── Reconstrução de Índices
     └─── Monitoramento de Uso
```

## 📊 Tabela Comparativa de Performance

```
┌───────────────────┬────────────┬────────────┬─────────────┐
│     OPERAÇÃO      │   ANTES    │   DEPOIS   │   MELHORIA  │
├───────────────────┼────────────┼────────────┼─────────────┤
│ Relatório Vendas  │   4.7s     │    0.8s    │     83%     │
│ Busca Produtos    │   3.2s     │    0.3s    │     91%     │
│ Análise Período   │   3.5s     │    0.6s    │     83%     │
│ Perfil Cliente    │   5.2s     │    0.7s    │     87%     │
│ Análise Estoque   │   4.1s     │    0.5s    │     88%     │
└───────────────────┴────────────┴────────────┴─────────────┘
``` 
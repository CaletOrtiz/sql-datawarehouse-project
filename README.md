

## 🛠️ Estructura del Repositorio

```text
├── data/              # Carpeta ignorada en Git (almacena el .sqlite local)
├── docs/              # Documentación técnica: arquitectura, ERD por capa, proceso ETL
├── scripts/           # SQL de las capas bronce, plata y oro
│   ├── bronce/        # DDL + carga de fuentes .tbl
│   ├── plata/         # Checks de calidad + DDL + ETL bronce→plata
│   └── oro/           # DDL estrella + ETL plata→oro
├── etl/               # Mapeo y scripts del proceso ETL / Limpieza
├── dashboard/         # Capturas de pantalla, reportes y archivos del Dashboard
├── .gitignore         # Configuración para ignorar archivos de datos pesados
└── README.md          # Descripción general del proyecto

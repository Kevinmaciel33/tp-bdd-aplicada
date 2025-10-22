CREATE TABLE persona (
    id_persona INT IDENTITY(1,1) PRIMARY KEY, 
    dni int NOT NULL UNIQUE,            
    nombre VARCHAR(40) NOT NULL,      
    apellido VARCHAR(40) NOT NULL,     
    email VARCHAR(255) UNIQUE,      
    telefono VARCHAR(50),              
    tipo smallint NOT NULL,             
    cuenta char(23)                         
);

ALTER TABLE persona
ADD CONSTRAINT CHK_persona_email_valido
CHECK (
    email LIKE '%@%.%'  
    AND email NOT LIKE '@%'
    AND email NOT LIKE '%.'
);
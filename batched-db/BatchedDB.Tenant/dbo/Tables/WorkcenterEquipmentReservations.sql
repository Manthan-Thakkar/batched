CREATE TABLE WorkcenterEquipmentReservations (
    Id VARCHAR(36) PRIMARY KEY NOT NULL,
    WorkcenterReservationId VARCHAR(36),
    EquipmentId VARCHAR(36),
    ReservedHours INT NOT NULL,
    CreatedOnUTC DATETIME NOT NULL,
    ModifiedOnUTC DATETIME NOT NULL,
    CONSTRAINT FK_WorkcenterEquipmentReservations FOREIGN KEY (WorkcenterReservationId) REFERENCES WorkcenterReservations(Id),
    CONSTRAINT FK_EquipmentMaster FOREIGN KEY (EquipmentId) REFERENCES EquipmentMaster(Id)
);
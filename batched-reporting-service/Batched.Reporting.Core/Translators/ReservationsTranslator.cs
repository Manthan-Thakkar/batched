using DataModels = Batched.Common.Data.Tenants.Sql.Models;
using Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Core.Translators
{
    public static class ReservationsTranslator
    {
        public static DataModels.Reservation TranslateToModelObject(this ReservationPayload payload)
        {
            var reservation = new DataModels.Reservation();
            var reservationId = Guid.NewGuid().ToString();
            reservation.Id = reservationId;
            reservation.Name = payload.Name;
            reservation.FacilityId = payload.FacilityId;
            reservation.StartDate = payload.StartDate;
            reservation.ExpirationDays = payload.ExpirationDays;
            reservation.IsRecurring = payload.IsRecurring;
            reservation.CreatedBy = payload.CreatedBy;
            reservation.ModifiedBy = payload.CreatedBy;
            reservation.CreatedOnUtc = DateTime.UtcNow;
            reservation.ModifiedOnUtc = DateTime.UtcNow;
            reservation.CustomerReservations = payload.Customers.Select(customerId => new DataModels.CustomerReservation
            {
                Id = Guid.NewGuid().ToString(),
                ReservationId = reservationId,
                CustomerId = customerId,
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow,

            }).ToList();

            foreach(var item in payload.WorkcenterReservations)
            {
                var workcenterReservationId = Guid.NewGuid().ToString();
                reservation.WorkcenterReservations.Add(new DataModels.WorkcenterReservation
                {
                    Id = workcenterReservationId,
                    ReservationId = reservationId,
                    WorkcenterTypeId = item.WorkcenterId,
                    WorkcenterName = item.WorkcenterName,
                    CreatedOnUtc = DateTime.UtcNow,
                    ModifiedOnUtc = DateTime.UtcNow,   
                    ReservedHours = item.ReservedHours,
                    WorkcenterEquipmentReservations = item.EquipmentReservations.Select(er => new DataModels.WorkcenterEquipmentReservation
                    {
                        Id = Guid.NewGuid().ToString(),
                        WorkcenterReservationId = workcenterReservationId,
                        EquipmentId = er.EquipmentId,
                        ReservedHours = er.ReservedHours,
                        CreatedOnUtc = DateTime.UtcNow,
                        ModifiedOnUtc = DateTime.UtcNow,
                    }).ToList(),
                });
            }

            return reservation; 
        }

        public static DataModels.ReservationRecurrence TranslateToModelObject(this ReservationRecurrencePayload payload)
        {
            return new DataModels.ReservationRecurrence()
            {
                Id = Guid.NewGuid().ToString(),
                Frequency = payload.Frequency,
                RecurrenceType = payload.RecurrenceType,
                IsRecurringMonthlyOnWeekDay = payload.IsRecurringMonthlyOnWeekDay,
                RecurrenceMonth = payload.RecurrenceMonth,
                RecurrenceDay = payload.RecurrenceDay,
                RecurrenceDayOfWeekIndex = payload.RecurrenceDayOfWeekIndex,
                RecurrenceWeekDays = string.Join(',', payload.RecurrenceWeekDays),
                EndDate = payload.EndDate,
                CreatedOnUtc = DateTime.UtcNow,
                ModifiedOnUtc = DateTime.UtcNow,
            };
        }

        public static List<DuplicateReservationValidationDto> GetWorkcenterEquipmentCombinations(List<DataModels.Reservation> existingReservations)
        {
            var result = new List<DuplicateReservationValidationDto>();

            foreach (var reservation in existingReservations)
            {
                foreach (var workcenter in reservation.WorkcenterReservations)
                {
                    if (workcenter.WorkcenterEquipmentReservations.Any())
                    {
                        foreach (var equipment in workcenter.WorkcenterEquipmentReservations)
                        {
                            if (reservation.CustomerReservations.Any())
                            {
                                result.AddRange(reservation.CustomerReservations.Select(csr => new DuplicateReservationValidationDto
                                {
                                    FacilityId = reservation.FacilityId,
                                    ReservationName = reservation.Name,
                                    CustomerId = csr.CustomerId,
                                    EquipmentId = equipment.EquipmentId,
                                    WorkcenterId = workcenter.WorkcenterTypeId,
                                    StartDate = reservation.StartDate,
                                    EndDate = reservation.ReservationRecurrence?.EndDate,
                                }).ToList());
                            }
                            else
                            {
                                result.Add(new DuplicateReservationValidationDto
                                {
                                    FacilityId = reservation.FacilityId,
                                    ReservationName = reservation.Name,
                                    CustomerId = null,
                                    EquipmentId = equipment.EquipmentId,
                                    WorkcenterId = workcenter.WorkcenterTypeId,
                                    StartDate = reservation.StartDate,
                                    EndDate = reservation.ReservationRecurrence?.EndDate,
                                });
                            }
                        }

                    }
                    else
                    {
                        if (reservation.CustomerReservations.Any())
                        {
                            result.AddRange(reservation.CustomerReservations.Select(csr => new DuplicateReservationValidationDto
                            {
                                FacilityId = reservation.FacilityId,
                                ReservationName = reservation.Name,
                                CustomerId = csr.CustomerId,
                                EquipmentId = null,
                                WorkcenterId = workcenter.WorkcenterTypeId,
                                StartDate = reservation.StartDate,
                                EndDate = reservation.ReservationRecurrence?.EndDate,
                            }).ToList());

                        }
                        else
                        {
                            result.Add(new DuplicateReservationValidationDto
                            {
                                FacilityId = reservation.FacilityId,
                                ReservationName = reservation.Name,
                                CustomerId = null,
                                EquipmentId = null,
                                WorkcenterId = workcenter.WorkcenterTypeId,
                                StartDate = reservation.StartDate,
                                EndDate = reservation.ReservationRecurrence?.EndDate,
                            });
                        }
                    }
                }
            }
            return result;
        }

        public static List<DuplicateReservationValidationDto> GetWorkcenterEquipmentCombinations(ReservationPayload payload)
        {
            var result = new List<DuplicateReservationValidationDto>();
            foreach (var workcenter in payload.WorkcenterReservations)
            {
                if (workcenter.EquipmentReservations.Any())
                {
                    foreach (var equipment in workcenter.EquipmentReservations)
                    {
                        if (payload.Customers.Any())
                        {
                            result.AddRange(payload.Customers.Select(customerId => new DuplicateReservationValidationDto
                            {
                                FacilityId = payload.FacilityId,
                                ReservationName = payload.Name,
                                CustomerId = customerId,
                                EquipmentId = equipment.EquipmentId,
                                WorkcenterId = workcenter.WorkcenterId,
                                StartDate = payload.StartDate,
                                EndDate = payload.ReservationRecurrence?.EndDate,
                            }).ToList());
                        }
                        else
                        {
                            result.Add(new DuplicateReservationValidationDto
                            {
                                FacilityId = payload.FacilityId,
                                ReservationName = payload.Name,
                                CustomerId = null,
                                EquipmentId = equipment.EquipmentId,
                                WorkcenterId = workcenter.WorkcenterId,
                                StartDate = payload.StartDate,
                                EndDate = payload.ReservationRecurrence?.EndDate,
                            });
                        }
                    }

                }
                else
                {
                    if (payload.Customers.Any())
                    {
                        result.AddRange(payload.Customers.Select(customerId => new DuplicateReservationValidationDto
                        {
                            FacilityId = payload.FacilityId,
                            ReservationName = payload.Name,
                            CustomerId = customerId,
                            EquipmentId = null,
                            WorkcenterId = workcenter.WorkcenterId,
                            StartDate = payload.StartDate,
                            EndDate = payload.ReservationRecurrence?.EndDate,
                        }).ToList());

                    }
                    else
                    {
                        result.Add(new DuplicateReservationValidationDto
                        {
                            FacilityId = payload.FacilityId,
                            ReservationName = payload.Name,
                            CustomerId = null,
                            EquipmentId = null,
                            WorkcenterId = workcenter.WorkcenterId,
                            StartDate = payload.StartDate,
                            EndDate = payload.ReservationRecurrence?.EndDate,
                        });
                    }
                }
            }
            return result;
        }

        public static List<Reservation> Translate(this List<DataModels.Reservation> reservations)
        {
            var result = new List<Reservation>();   
            foreach (var reservation in reservations)
            {
                var resultReservation = new Reservation()
                {
                    Id = reservation.Id,
                    Name = reservation.Name,
                    StartDate = reservation.StartDate,
                    FacilityId = reservation.FacilityId,
                    FacilityName = reservation.Facility.Name,
                    WorkcenterReservations = TranslateToWorkcenterReservation(reservation.WorkcenterReservations.ToList()),
                    IsRecurring = reservation.IsRecurring,
                    ReservationRecurrence = reservation.ReservationRecurrence?.Translate(),
                    ExpirationDays = reservation.ExpirationDays,
                    Customers = reservation.CustomerReservations
                            .Select(x => new CustomerDto { Id = x.CustomerId, Name = x.Customer.CustomerName}).ToList(),
                    CreatedBy = reservation.CreatedBy,
                    ModifiedBy = reservation.ModifiedBy,
                };
                
                result.Add(resultReservation);
            }
            return result;
        }

        private static ReservationRecurrence Translate(this DataModels.ReservationRecurrence reservationRecurrence)
        {
            return new ReservationRecurrence()
            {
                Frequency = reservationRecurrence.Frequency,    
                RecurrenceType = reservationRecurrence.RecurrenceType,
                RecurrenceDay = reservationRecurrence.RecurrenceDay,
                RecurrenceMonth = reservationRecurrence.RecurrenceMonth,
                RecurrenceDayOfWeekIndex = reservationRecurrence.RecurrenceDayOfWeekIndex,
                RecurrenceWeekDays = reservationRecurrence.RecurrenceWeekDays.Split(',').ToList(),
                IsRecurringMonthlyOnWeekDay = reservationRecurrence.IsRecurringMonthlyOnWeekDay,
                EndDate = reservationRecurrence.EndDate,
            };
        }
        private static List<EquipmentReservation> TranslateToEquipmentReservations(List<DataModels.WorkcenterEquipmentReservation> equipmentReservation)
        {
            var result = new List<EquipmentReservation>();
            foreach (var item in equipmentReservation)
            {
                result.Add(new EquipmentReservation()
                {
                    EquipmentId = item.EquipmentId,
                    EquipmentName = item.Equipment.Name,
                    ReservedHours = item.ReservedHours,
                });
            }
            return result;
        }
        private static List<WorkcenterReservation> TranslateToWorkcenterReservation(List<DataModels.WorkcenterReservation> workcenterReservation)
        {
            var result = new List<WorkcenterReservation>();
            foreach (var item in workcenterReservation)
            {
                result.Add(new WorkcenterReservation()
                {
                    WorkcenterId = item.WorkcenterTypeId,
                    WorkcenterName = item.WorkcenterName,
                    ReservedHours = item.ReservedHours,
                    EquipmentReservations = TranslateToEquipmentReservations(item.WorkcenterEquipmentReservations.ToList()),
                });
            }
            return result;
        }
    }
}

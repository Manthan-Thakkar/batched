using Batched.Common;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models.Reservations;
using Microsoft.EntityFrameworkCore;
using Models = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Data
{
    public class ReservationsRepository : IReservationsRepository
    {
        private readonly UnitOfWorkFactory _unitOfWorkFactory;
        public ReservationsRepository(UnitOfWorkFactory unitOfWorkFactory)
        {
            _unitOfWorkFactory = unitOfWorkFactory;
        }

        public async Task<List<Models.Reservation>> GetAllReservationsAsync(CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("reservation-repository-get-all-reservations"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<Models.Reservation>().GetQueryable()
                    .Include(x => x.ReservationRecurrence)
                    .Include(x => x.Facility)
                    .Include(x => x.CustomerReservations).ThenInclude(x => x.Customer)
                    .Include(x => x.WorkcenterReservations)
                        .ThenInclude(x => x.WorkcenterEquipmentReservations)
                        .ThenInclude(x => x.Equipment).ToListAsync(cancellationToken: cancellationToken);
            }
        }

        public async Task<List<ReservationEventDto>> GetReservationEventAsync(CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("reservation-repository-get-all-reservation-events"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<Models.ReservationEvent>().GetQueryable()
                    .Where(x => !x.IsExpired)
                    .Select(x => new ReservationEventDto
                    {
                        Id = x.Id,
                        Date = x.ReservationEventDate,
                        ActualDemand = x.ReservedDemands.Any() ? x.ReservedDemands.First().ActualDemand : 0,
                        NetReservedDemand = x.ReservedDemands.Any() ? x.ReservedDemands.First().NetReservedDemand : x.ReservedDemand,
                        WorkcenterId = x.WorkcenterId,
                        EquipmentId = x.EquipmentId,
                    })
                    .ToListAsync();
            }
        }


        public async Task<Models.Reservation> GetReservationAsync(string reservationId, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("reservation-repository-get-reservation-by-id"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.read))
            {
                return await unitOfWork.Repository<Models.Reservation>().GetQueryable()
                    .Where(x => x.Id == reservationId)
                    .Include(x => x.ReservationRecurrence)
                    .Include(x => x.Facility)
                    .Include(x => x.CustomerReservations).ThenInclude(x => x.Customer)
                    .Include(x => x.WorkcenterReservations)
                        .ThenInclude(x => x.WorkcenterEquipmentReservations)
                        .ThenInclude(x => x.Equipment).FirstOrDefaultAsync(cancellationToken: cancellationToken);
            }
        }

        public async Task<string> AddReservationAsync(Models.Reservation reservation, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("reservation-repository-add-reservation"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                await unitOfWork.Repository<Models.Reservation>().AddAsync(reservation);
                unitOfWork.Complete();
                return reservation.Id;
            }
        }

        public async Task UpdateReservationAsync(Models.Reservation reservation, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("reservation-repository-add-reservation"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var currentReservation = await unitOfWork.Repository<Models.Reservation>().GetQueryable()
                                                .FirstOrDefaultAsync(x => x.Id == reservation.Id, cancellationToken:cancellationToken);

                await unitOfWork.Repository<Models.WorkcenterEquipmentReservation>().RemoveRangeAsync(currentReservation.WorkcenterReservations.SelectMany(x => x.WorkcenterEquipmentReservations).ToList());
                await unitOfWork.Repository<Models.WorkcenterReservation>().RemoveRangeAsync(currentReservation.WorkcenterReservations.ToList());
                await unitOfWork.Repository<Models.CustomerReservation>().RemoveRangeAsync(currentReservation.CustomerReservations.ToList());
                
                if(currentReservation.IsRecurring)
                    await unitOfWork.Repository<Models.ReservationRecurrence>().RemoveAsync(currentReservation.ReservationRecurrence);

                var updatedReservation = UpdateReservationValues(reservation, currentReservation);

                await unitOfWork.Repository<Models.Reservation>().UpdateAsync(updatedReservation);
                unitOfWork.Complete();
            }
        }

        public async Task DeleteReservationAsync(string reservationId, CancellationToken cancellationToken)
        {
            using (Tracer.Benchmark("reservation-repository-delete-reservation"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var currentReservation = await unitOfWork.Repository<Models.Reservation>().GetQueryable()
                                                .FirstOrDefaultAsync(x => x.Id == reservationId, cancellationToken:cancellationToken);
                var currentReservationRecurrence = currentReservation.ReservationRecurrence;

                await unitOfWork.Repository<Models.WorkcenterEquipmentReservation>().RemoveRangeAsync(currentReservation.WorkcenterReservations
                                                                .SelectMany(x => x.WorkcenterEquipmentReservations).ToList());
                await unitOfWork.Repository<Models.WorkcenterReservation>().RemoveRangeAsync(currentReservation.WorkcenterReservations.ToList());
                await unitOfWork.Repository<Models.CustomerReservation>().RemoveRangeAsync(currentReservation.CustomerReservations.ToList());
                await unitOfWork.Repository<Models.Reservation>().RemoveAsync(currentReservation);
                
                if(currentReservation.IsRecurring)
                    await unitOfWork.Repository<Models.ReservationRecurrence>().RemoveAsync(currentReservation.ReservationRecurrence);

                unitOfWork.Complete();
            }
        }

        public async Task AddReservationEventsAsync(List<Models.ReservationEvent> reservationEvents)
        {
            using (Tracer.Benchmark("reservation-repository-add-reservation-events"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                await unitOfWork.Repository<Models.ReservationEvent>().AddRangeAsync(reservationEvents);
                unitOfWork.Complete();
            }
        }

        public async Task RemoveReservationEventsAsync(string reservationId)
        {
            using (Tracer.Benchmark("reservation-repository-remove-reservation-events"))
            using (var unitOfWork = _unitOfWorkFactory.BeginUnitOfWork(DBContextLevel.Tenant, DbAccessMode.write))
            {
                var events = await unitOfWork.Repository<Models.ReservationEvent>().GetQueryable()
                    .Where(x => x.ReservationId == reservationId).ToListAsync();

                foreach (var e in events)
                {
                    var reservationsTaskAllocationsTemp =  await unitOfWork.Repository<Models.ReservationTaskAllocationTemp>().GetMultiAsync(x => x.ReservationEventId == e.Id);
                    var reservedDemandTemp = await unitOfWork.Repository<Models.ReservedDemandTemp>().GetMultiAsync(x => x.ReservationEventId == e.Id);
                    
                    if(reservationsTaskAllocationsTemp != null && reservationsTaskAllocationsTemp.Any())
                        await unitOfWork.Repository<Models.ReservationTaskAllocationTemp>().RemoveRangeAsync(reservationsTaskAllocationsTemp.ToList());

                    if (reservedDemandTemp != null && reservedDemandTemp.Any())
                        await unitOfWork.Repository<Models.ReservedDemandTemp>().RemoveRangeAsync(reservedDemandTemp.ToList());
                    
                    await unitOfWork.Repository<Models.ReservationTaskAllocation>().RemoveRangeAsync(e.ReservationTaskAllocations.ToList());
                    await unitOfWork.Repository<Models.ReservedDemand>().RemoveRangeAsync(e.ReservedDemands.ToList());
                }

                await unitOfWork.Repository<Models.ReservationEvent>().RemoveRangeAsync(events);

                unitOfWork.Complete();
            }
        }


        private static Models.Reservation UpdateReservationValues(Models.Reservation newReservation, Models.Reservation currentReservation)
        {
            currentReservation.Name = newReservation.Name;
            currentReservation.StartDate = newReservation.StartDate;
            currentReservation.IsRecurring = newReservation.IsRecurring;
            currentReservation.ModifiedOnUtc = newReservation.ModifiedOnUtc;
            currentReservation.FacilityId = newReservation.FacilityId;
            currentReservation.ReservationRecurrenceId = newReservation.ReservationRecurrenceId;
            currentReservation.ReservationRecurrence = newReservation.ReservationRecurrence;
            currentReservation.WorkcenterReservations = newReservation.WorkcenterReservations;
            currentReservation.CustomerReservations = newReservation.CustomerReservations;
            currentReservation.ExpirationDays = newReservation.ExpirationDays;
            currentReservation.ModifiedBy = newReservation.ModifiedBy;
            return currentReservation;
        }
    }
}

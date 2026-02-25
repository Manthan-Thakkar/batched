using Batched.Reporting.Contracts;
using Batched.Reporting.Contracts.Interfaces;
using Batched.Reporting.Contracts.Models;
using Batched.Reporting.Contracts.Models.LeadTimeManager;
using Batched.Reporting.Contracts.Models.Reservations;
using Batched.Reporting.Core;
using Batched.Reporting.Test.MockedEntities;
using Moq;
using Xunit;
using DtaModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.Core
{
    public class LeadTimeProviderTest : BaseTest<LeadTimeReportProvider>
    {
        private readonly Mock<IEquipmentRepository> _equipmentRepository;
        private readonly Mock<ICachedEquipmentRepository> _cachedEquipmentRepository;
        private readonly Mock<ITicketTaskRepository> _ticketTaskRepository;
        private readonly Mock<IFacilityRepository> _facilityRepository;
        private readonly Mock<ITenantRepository> _tenantRepository;
        private readonly Mock<IReservationsRepository> _reservationRepository;
        private readonly Mock<IConfigurableViewsProvider> _configurableViewsProvider;

        public LeadTimeProviderTest() : base(typeof(IEquipmentRepository), typeof(IFacilityRepository), typeof(ICachedEquipmentRepository),
            typeof(ITicketTaskRepository), typeof(ITenantRepository), typeof(IReservationsRepository), typeof(IConfigurableViewsProvider))
        {
            _equipmentRepository = new Mock<IEquipmentRepository>();
            _cachedEquipmentRepository = new Mock<ICachedEquipmentRepository>();
            _ticketTaskRepository = new Mock<ITicketTaskRepository>();
            _facilityRepository = new Mock<IFacilityRepository>();
            _tenantRepository = new Mock<ITenantRepository>();
            _reservationRepository = new Mock<IReservationsRepository>();
            _configurableViewsProvider = new Mock<IConfigurableViewsProvider>();
        }

        [Fact]
        public async Task GetFilterDataAsync_ShouldReturnData()
        {
            _equipmentRepository
                .Setup(_ => _.GetEquipmentWiseTicketsAysnc(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<EquipmentTicket>());

            _cachedEquipmentRepository
                .Setup(_ => _.GetFilterDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<FilterData>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var filterData = await leadTimeProvider.GetFilterDataAsync(new DashboardFilter(), CancellationToken.None);

            Assert.NotNull(filterData);
        }

        [Fact]
        public async Task GetKpiAsync_ShouldReturnData_AllTickets()
        {
            var startDate = new DateTime(2024, 4, 10);
            var endDate = new DateTime(2024, 6, 10);
            var totalTickets = GetTicketsDemands().Select(x => x.TicketId).Distinct().Count();
            var externalLeadTimeDays = GetAllEquipmentDetailsData().Max(x => x.MinLeadTime);
            var reservedDemand = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.Date >= startDate && x.Date <= endDate)
                                .Sum(x => x.NetReservedDemand);

            _equipmentRepository
                .Setup(_ => _.GetMaxEquipmentCalendarDate())
                .ReturnsAsync(new DateTime(2024, 6, 2));

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _facilityRepository
                .Setup(_ => _.GetFacilityHolidaysCountAsync(It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<FacilityHolidaysCount>());

            _facilityRepository
                .Setup(_ => _.GetAllFacilityWiseHolidays(It.IsAny<List<string>>()))
                .ReturnsAsync(new List<FacilityWiseHolidays>());

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetReservationEvents(new DateTime(2024, 4, 10)));

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var kpidata = await leadTimeProvider.GetKpiAsync(new DashboardFilter() { StartDate = startDate, EndDate = endDate }, CancellationToken.None);

            Assert.NotNull(kpidata);
            Assert.Equal(totalTickets, kpidata.TotalTickets);
            Assert.Equal(externalLeadTimeDays, kpidata.ExternalLeadTimeDays);
            Assert.Equal(reservedDemand, kpidata.Reservations);
        }


        [Fact]
        public async Task GetKpiAsync_ShouldReturnData_AllTickets_WithTicketFilter()
        {
            var startDate = new DateTime(2024, 4, 10);
            var endDate = new DateTime(2024, 6, 10);
            var ticketsToFilter = new List<string>() { "5112", "5113" };
            var reservedDemand = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.Date >= startDate && x.Date <= endDate)
                                .Sum(x => x.NetReservedDemand);

            _equipmentRepository
                .Setup(_ => _.GetMaxEquipmentCalendarDate())
                .ReturnsAsync(new DateTime(2024, 6, 2));

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _facilityRepository
                .Setup(_ => _.GetFacilityHolidaysCountAsync(It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<FacilityHolidaysCount>());

            _facilityRepository
                .Setup(_ => _.GetAllFacilityWiseHolidays(It.IsAny<List<string>>()))
                .ReturnsAsync(new List<FacilityWiseHolidays>());

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetReservationEvents(new DateTime(2024, 4, 10)));

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var kpidataTicketsFiltered = await leadTimeProvider.GetKpiAsync(new DashboardFilter()
            {
                StartDate = startDate,
                Tickets = ticketsToFilter,
                EndDate = endDate
            }, CancellationToken.None);

            Assert.NotNull(kpidataTicketsFiltered);
            Assert.Equal(ticketsToFilter.Count, kpidataTicketsFiltered.TotalTickets);
            Assert.Equal(reservedDemand, kpidataTicketsFiltered.Reservations);
        }

        [Fact]
        public async Task GetKpiAsync_ShouldReturnData_AllTickets_WithEquipmentFilter()
        {
            var startDate = new DateTime(2024, 4, 10);
            var endDate = new DateTime(2024, 6, 10);
            var equipmentsToFilter = new List<string>() { "equip1", "equip2" };
            var totalTickets = GetTicketsDemands().Where(x => equipmentsToFilter.Contains(x.EquipmentId))
                .Select(x => x.TicketId).Distinct().Count();
            var reservedDemand = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.Date >= startDate && x.Date <= endDate
                                    && (x.EquipmentId == "equip1" || x.EquipmentId == "equip2"))
                                .Sum(x => x.NetReservedDemand);

            _equipmentRepository
                .Setup(_ => _.GetMaxEquipmentCalendarDate())
                .ReturnsAsync(new DateTime(2024, 6, 2));

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands().Where(x => equipmentsToFilter.Contains(x.EquipmentId)).ToList());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _facilityRepository
                .Setup(_ => _.GetFacilityHolidaysCountAsync(It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<FacilityHolidaysCount>());

            _facilityRepository
                .Setup(_ => _.GetAllFacilityWiseHolidays(It.IsAny<List<string>>()))
                .ReturnsAsync(new List<FacilityWiseHolidays>());

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetReservationEvents(new DateTime(2024, 4, 10)));

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var kpidataEquipmentsFiltered = await leadTimeProvider.GetKpiAsync(new DashboardFilter()
            {
                StartDate = startDate,
                Equipments = equipmentsToFilter,
                EndDate = endDate
            }, CancellationToken.None);

            Assert.NotNull(kpidataEquipmentsFiltered);
            Assert.Equal(totalTickets, kpidataEquipmentsFiltered.TotalTickets);
            Assert.Equal(reservedDemand, kpidataEquipmentsFiltered.Reservations);
        }

        [Fact]
        public async Task GetCapacitySummaryAsync_ShouldReturnData_AllTickets()
        {
            var totalTickets = GetTicketsDemands().Select(x => x.TicketId).Distinct().Count();
            var equip1Tickets = GetTicketsDemands().Where(x => x.EquipmentId == "equip1")
               .Select(x => x.TicketId).Distinct().Count();
            var reservedDemandEquip1 = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.EquipmentId == "equip1").Sum(x => x.NetReservedDemand);

            var externalLeadTimeDays = GetDailyEquipmentCapacities().Max(x => x.InternalLeadTime);

            _equipmentRepository
                .Setup(_ => _.GetMaxEquipmentCalendarDate())
                .ReturnsAsync(new DateTime(2024, 6, 2));

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _facilityRepository
                .Setup(_ => _.GetFacilityHolidaysCountAsync(It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<FacilityHolidaysCount>());

            _facilityRepository
                .Setup(_ => _.GetAllFacilityWiseHolidays(It.IsAny<List<string>>()))
                .ReturnsAsync(new List<FacilityWiseHolidays>());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetReservationEvents(new DateTime(2024, 4, 10)));

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var CapacitySummaryData = await leadTimeProvider.GetCapacitySummaryAsync(new DashboardFilter()
            {
                Equipments = new List<string>(),
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 6, 10)
            }, CancellationToken.None);

            Assert.NotNull(CapacitySummaryData);
            Assert.Equal(totalTickets, CapacitySummaryData.Sum(x => x.CapacitySummaryData.TotalTickets));
            var facility1Data = CapacitySummaryData.Where(x => x.Id == "facility1").First().DownStreamSummary;
            var facility2Data = CapacitySummaryData.Where(x => x.Id == "facility2").First().DownStreamSummary;
            var facility1Cap = CapacitySummaryData.Where(x => x.Id == "facility1").First().CapacitySummaryData.AvailableCapacity;
            var facility2Cap = CapacitySummaryData.Where(x => x.Id == "facility2").First().CapacitySummaryData.AvailableCapacity;
            var totalAvailableCap = facility1Cap + facility2Cap;
            var vs1data = facility1Data.Where(x => x.Id == "vs1").First().DownStreamSummary;
            var ws1Data = vs1data.Where(x => x.Id == "wc1").First().DownStreamSummary;
            var equip1TotalTickets = ws1Data.Where(x => x.Id == "equip1").First().CapacitySummaryData.TotalTickets;
            var equip1ReservedDemand = ws1Data.Where(x => x.Id == "equip1").First().CapacitySummaryData.ReservedDemand;
            Assert.Equal(equip1Tickets, equip1TotalTickets);
            Assert.Equal(reservedDemandEquip1, equip1ReservedDemand);
        }

        [Fact]
        public async Task GetCapacitySummaryAsync_ShouldReturnData_WithTicketFilter()
        {
            var ticketsToFilter = new List<string>() { "5112", "5113" };
            var totalTickets = ticketsToFilter.Count;
            var equip2Tickets = GetTicketsDemands().Where(x => x.EquipmentId == "equip2")
               .Select(x => x.TicketId).Distinct().Count();
            var mockedReservedDemandEquip2 = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.EquipmentId == "equip2").Sum(x => x.NetReservedDemand);

            var externalLeadTimeDays = GetDailyEquipmentCapacities().Max(x => x.InternalLeadTime);

            _equipmentRepository
                .Setup(_ => _.GetMaxEquipmentCalendarDate())
                .ReturnsAsync(new DateTime(2024, 6, 2));

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _facilityRepository
                .Setup(_ => _.GetFacilityHolidaysCountAsync(It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<FacilityHolidaysCount>());

            _facilityRepository
                .Setup(_ => _.GetAllFacilityWiseHolidays(It.IsAny<List<string>>()))
                .ReturnsAsync(new List<FacilityWiseHolidays>());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var CapacitySummaryData = await leadTimeProvider.GetCapacitySummaryAsync(new DashboardFilter()
            {
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 6, 10),
                Tickets = ticketsToFilter
            }, CancellationToken.None);

            Assert.NotNull(CapacitySummaryData);
            Assert.Equal(totalTickets, CapacitySummaryData.Sum(x => x.CapacitySummaryData.TotalTickets));

            var facility1Data = CapacitySummaryData.Where(x => x.Id == "facility1").First().DownStreamSummary;
            var vs1data = facility1Data.Where(x => x.Id == "vs1").First().DownStreamSummary;
            var ws1Data = vs1data.Where(x => x.Id == "wc1").First().DownStreamSummary;
            var equip2TotalTickets = ws1Data.Where(x => x.Id == "equip2").First().CapacitySummaryData.TotalTickets;
            var equip2ReservedDemand = ws1Data.Where(x => x.Id == "equip2").First().CapacitySummaryData.ReservedDemand;
            Assert.Equal(equip2Tickets, equip2TotalTickets);
            Assert.Equal(mockedReservedDemandEquip2, equip2ReservedDemand);
        }

        [Fact]
        public async Task GetCapacitySummaryAsync_GetKpiAsync_ShouldHaveSameValues_WithSameFilters()
        {
            var totalTickets = GetTicketsDemands().Select(x => x.TicketId).Distinct().Count();

            var externalLeadTimeDays = GetDailyEquipmentCapacities().Max(x => x.InternalLeadTime);

            _equipmentRepository
                .Setup(_ => _.GetMaxEquipmentCalendarDate())
                .ReturnsAsync(new DateTime(2024, 6, 2));

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _facilityRepository
                .Setup(_ => _.GetFacilityHolidaysCountAsync(It.IsAny<List<string>>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<FacilityHolidaysCount>());

            _facilityRepository
                .Setup(_ => _.GetAllFacilityWiseHolidays(It.IsAny<List<string>>()))
                .ReturnsAsync(new List<FacilityWiseHolidays>());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var CapacitySummaryData = await leadTimeProvider.GetCapacitySummaryAsync(new DashboardFilter()
            {
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 6, 10)
            }, CancellationToken.None);

            var kpidata = await leadTimeProvider.GetKpiAsync(new DashboardFilter()
            {
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 6, 10)
            }, CancellationToken.None);

            Assert.NotNull(CapacitySummaryData);
            Assert.NotNull(kpidata);

            Assert.Equal(totalTickets, CapacitySummaryData.Sum(x => x.CapacitySummaryData.TotalTickets));

            var facility1Cap = CapacitySummaryData.Where(x => x.Id == "facility1").First().CapacitySummaryData.AvailableCapacity;
            var facility2Cap = CapacitySummaryData.Where(x => x.Id == "facility2").First().CapacitySummaryData.AvailableCapacity;
            var totalAvailableCapaictyFromSummary = facility1Cap + facility2Cap;

            var availableCapacityFromSummary = Math.Ceiling(totalAvailableCapaictyFromSummary);
            var availableCapacityFromKPI = Math.Ceiling(kpidata.AvailableCapacity);
            var totalTicketsFromSummary = CapacitySummaryData.Sum((x) => x.CapacitySummaryData.TotalTickets);
            var totalTicketsFromKpi = kpidata.TotalTickets;

            Assert.Equal(availableCapacityFromSummary, availableCapacityFromKPI);
            Assert.Equal(totalTicketsFromKpi, totalTicketsFromSummary);
        }


        [Fact]
        public async Task GetCapacityOverviewAsync_ShouldReturnData_AllTickets()
        {
            var equipsHavingNetReservedDemand = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.NetReservedDemand > 0)
                                                .Select(x => x.EquipmentId).Distinct().ToList();
            var facilitiesHavingReservedDemand = GetAllEquipmentDetailsData().Where(x => equipsHavingNetReservedDemand.Contains(x.EquipmentId))
                                                .Select(x => x.FacilityId).Distinct().ToList();
            var datesHavingReservedDemand = GetReservationEvents(new DateTime(2024, 4, 10)).Where(x => x.NetReservedDemand > 0)
                                                .Select(x => x.Date).ToList();

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetReservationEvents(new DateTime(2024, 4, 10)));

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var CapacityOverviewData = await leadTimeProvider.GetCapacityOverviewsAsync(new DashboardFilter()
            {
                Equipments = new List<string>(),
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 5, 10)
            }, CancellationToken.None);

            Assert.NotNull(CapacityOverviewData);
            Assert.Equal(2, CapacityOverviewData.Count);

            var capacityOverviewHavingReservedDemand = CapacityOverviewData.Where(x => facilitiesHavingReservedDemand.Contains(x.Id)).ToList();
            foreach (var capacityOverview in capacityOverviewHavingReservedDemand)
            {
                foreach (var date in datesHavingReservedDemand)
                {
                    var isDemandPositive = capacityOverview.CapacityOverviewData.Where(data => data.TheDate == date).Any() ?
                        (capacityOverview.CapacityOverviewData.Where(data => data.TheDate == date).First().TotalDemandHours > 0) : true;
                    Assert.True(isDemandPositive);
                }

            }
        }

        [Fact]
        public async Task GetCapacityOverviewAsync_ShouldReturnData_WithFacilityFilter()
        {
            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var CapacityOverviewData = await leadTimeProvider.GetCapacityOverviewsAsync(new DashboardFilter()
            {
                Equipments = new List<string>(),
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 5, 10),
                Facilities = new List<string> { "facility1" },
            }, CancellationToken.None);

            var facilityName = GetAllEquipmentDetailsData().Where(x => x.FacilityId == "facility1").First().FacilityName;

            Assert.NotNull(CapacityOverviewData);
            Assert.Single(CapacityOverviewData);
            Assert.Equal(facilityName, CapacityOverviewData.First().Name);
        }

        [Fact]
        public async Task GetCapacityOverviewAsync_ShouldReturnData_WithEquipmentsWithNoCapacity()
        {
            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _ticketTaskRepository
                .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetEquipmentsCapacityAsync(It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetDailyEquipmentCapacities());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
                _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var CapacityOverviewData = await leadTimeProvider.GetCapacityOverviewsAsync(new DashboardFilter()
            {
                Equipments = new List<string>() { "equip5" },
                StartDate = new DateTime(2024, 4, 10),
                EndDate = new DateTime(2024, 5, 10),
            }, CancellationToken.None);

            var equipmentName = GetAllEquipmentDetailsData().Where(x => x.EquipmentId == "equip5").First().EquipmentName;
            var equipmentsFacility = GetAllEquipmentDetailsData().Where(x => x.EquipmentId == "equip5").First().FacilityName;
            var equipmentsWorkcenter = GetAllEquipmentDetailsData().Where(x => x.EquipmentId == "equip5").First().WorkcenterName;
            var equipmentsValueStream = GetAllEquipmentDetailsData().Where(x => x.EquipmentId == "equip5").First().ValueStreams.First().Name;

            Assert.NotNull(CapacityOverviewData);
            Assert.Single(CapacityOverviewData);
            Assert.Equal(equipmentsFacility, CapacityOverviewData.First().Name);
            Assert.Equal(equipmentsValueStream, CapacityOverviewData.First().DownStreamOverview.First().Name);
            Assert.Equal(equipmentsWorkcenter, CapacityOverviewData.First().DownStreamOverview.First().DownStreamOverview.First().Name);
            Assert.Equal(equipmentName, CapacityOverviewData.First().DownStreamOverview.First().DownStreamOverview.First().DownStreamOverview.First().Name);
        }

        //[Fact]
        //public async Task GetOpenTicketDetailsAsync_ShouldSucceed()
        //{
        //    _configurableViewsProvider
        //        .Setup(x => x.GetConfigurableViewFieldsAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(new ConfigurableViewField { NoViewFound = false, Columns = new() });

        //    _ticketTaskRepository
        //        .Setup(x => x.GetOpenTicketsLTMAsync(It.IsAny<LeadTimeManagerFilters>(), It.IsAny<List<string>>(), It.IsAny<CancellationToken>()))
        //        .ReturnsAsync((new List<OpenTicketDetailsLTM>(), 0));

        //    var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object,
        //        _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);

        //    var openTicketsData = await leadTimeProvider.GetOpenTicketsLTMAsync(new LeadTimeManagerFilters(), CancellationToken.None);

        //    Assert.NotNull(openTicketsData);
        //}

        //[Fact]
        //public async Task GetOpenTicketDetailsAsync_ShouldSucceed_WithAllLateTasks()
        //{
        //    var openTicketDtos = GetOpoenTicketDetailsDtos();
        //    openTicketDtos.ForEach(x =>
        //    {
        //        x.ShipByDate = DateTime.Today.AddDays(10);
        //        x.EstMaxDueDateTime = DateTime.Today.AddDays(5);
        //        x.ScheduledTaskEndsAt = DateTime.Today.AddDays(7);
        //    });

        //    _ticketTaskRepository.
        //        Setup(x => x.GetOpenTicketDetailsAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(openTicketDtos);

        //    _ticketTaskRepository
        //        .Setup(x => x.GetLastJobRunInfoAsync(It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(GetLastRunInfos());

        //    var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
        //    var openTicketsData = await leadTimeProvider.GetOpenTicketDetailsAsync(new DashboardFilter()
        //    {
        //        StartDate = DateTime.Today,
        //        EndDate = DateTime.Today.AddDays(12)
        //    }, CancellationToken.None);

        //    Assert.NotNull(openTicketsData);
        //    Assert.True(openTicketsData.OpenTicketDetails.All(x => x.TaskStatus == Constants.TaskStatus.Late));

        //}

        //[Fact]
        //public async Task GetOpenTicketDetailsAsync_ShouldSucceed_WithAllTasksAtRisk()
        //{
        //    var openTicketDtos = GetOpoenTicketDetailsDtos();

        //    openTicketDtos.ToList().ForEach(x =>
        //    {
        //        x.EstMaxDueDateTime = DateTime.Today.AddDays(2);
        //        x.ScheduledTaskEndsAt = DateTime.Today.AddDays(2).AddHours(-2);
        //        x.ShipByDate = DateTime.Today.AddDays(5);
        //    });

        //    _ticketTaskRepository
        //        .Setup(x => x.GetOpenTicketDetailsAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(openTicketDtos);

        //    _ticketTaskRepository
        //        .Setup(x => x.GetLastJobRunInfoAsync(It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(GetLastRunInfos());

        //    var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
        //    var openTicketsData = await leadTimeProvider.GetOpenTicketDetailsAsync(new DashboardFilter()
        //    {
        //        StartDate = DateTime.Today,
        //        EndDate = DateTime.Today.AddDays(12)
        //    }, CancellationToken.None);

        //    Assert.NotNull(openTicketsData);
        //    Assert.True(openTicketsData.OpenTicketDetails.All(x => x.TaskStatus == Constants.TaskStatus.AtRisk));

        //}

        //[Fact]
        //public async Task GetOpenTicketDetailsAsync_ShouldMarkOnPress()
        //{
        //    var openTicketDtos = GetOpoenTicketDetailsDtos();

        //    _ticketTaskRepository
        //        .Setup(x => x.GetOpenTicketDetailsAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(openTicketDtos);

        //    var lastRunInfo = new List<LastRunInfo>()
        //    {
        //        new LastRunInfo()
        //        {
        //            LastRunEquipmentId = "e1",
        //            SourceTicketId = "11112"
        //        },
        //    };
        //    _ticketTaskRepository
        //        .Setup(x => x.GetLastJobRunInfoAsync(It.IsAny<CancellationToken>()))
        //        .ReturnsAsync(lastRunInfo);

        //    var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
        //    var openTicketsData = await leadTimeProvider.GetOpenTicketDetailsAsync(new DashboardFilter()
        //    {
        //        StartDate = DateTime.Today,
        //        EndDate = DateTime.Today.AddDays(12)
        //    }, CancellationToken.None);

        //    Assert.NotNull(openTicketsData);
        //    Assert.True(openTicketsData.OpenTicketDetails.Where(x => x.TicketId == "ticket2").First().IsOnPress);

        //}

        [Fact]
        public async Task GetCapacityOutLookOverTimeAsync_ShouldSucceed()
        {
            var reservationEventsHavingNetReservedDemand = GetReservationEvents(DateTime.Today).Where(x => x.NetReservedDemand > 0).ToList();

            var equip1CapacityHours = MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip1")
                .First().CapacityHours;

            var equip1UnplannedAllowanceHours = MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip1")
                .First().UnplannedAllowanceHours;

            var equip2CapacityHours = MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip2")
                .First().CapacityHours;

            var equip2UnplannedAllowanceHours = MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip2")
               .First().UnplannedAllowanceHours;

            var day1TotalCapacity = equip1CapacityHours + equip2CapacityHours - equip1UnplannedAllowanceHours - equip2UnplannedAllowanceHours;

            _tenantRepository
                .Setup(_ => _.GetTenantCurrentTimeAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(DateTime.Today);

            _ticketTaskRepository
               .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
               .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetDailyEquipmentCapacityOutlookAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5));

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetReservationEvents(DateTime.Today));

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var capacityOutlookData = await leadTimeProvider.GetCapacityOutlookOverTimeAsync(new DashboardFilter()
            {
                StartDate = DateTime.Today,
                EndDate = DateTime.Today.AddDays(60)
            }, CancellationToken.None);

            Assert.NotNull(capacityOutlookData);
            var capacityOutLookFirstDayTotalCapacity = capacityOutlookData.CapacityOutlookOverTime.First().TotalCapacity;
            Assert.Equal(capacityOutLookFirstDayTotalCapacity, day1TotalCapacity);
            foreach (var reservationEvent in reservationEventsHavingNetReservedDemand)
            {
                var reservedDemand = capacityOutlookData.CapacityOutlookOverTime.Where(x => x.Date == reservationEvent.Date).First().ReservedDemand;
                Assert.Equal(reservationEvent.NetReservedDemand, reservedDemand);
            }
        }

        [Fact]
        public async Task GetCapacityOutLookOverTimeAsync_ShouldFilterByEquipment()
        {
            var reservationEventsHavingNetReservedDemand = GetReservationEvents(DateTime.Today)
                                    .Where(x => x.NetReservedDemand > 0 && x.EquipmentId == "equip2").ToList();

            var equip2CapacityHours = MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip2")
                .First().CapacityHours;

            var equip2UnplannedAllowanceHours = MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip2")
               .First().UnplannedAllowanceHours;

            var day1CapacityFilteredByEquipment2 = equip2CapacityHours - equip2UnplannedAllowanceHours;

            _tenantRepository
                .Setup(_ => _.GetTenantCurrentTimeAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(DateTime.Today);

            _ticketTaskRepository
               .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
               .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetDailyEquipmentCapacityOutlookAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(5, 5).Where(x => x.EquipmentId == "equip2").ToList());

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var capacityOutlookData = await leadTimeProvider.GetCapacityOutlookOverTimeAsync(new DashboardFilter()
            {
                StartDate = DateTime.Today,
                EndDate = DateTime.Today.AddDays(12),
                Equipments = new List<string> { "equip2" }
            }, CancellationToken.None);

            Assert.NotNull(capacityOutlookData);
            var firstDayTotalCapacityForEquipment2 = capacityOutlookData.CapacityOutlookOverTime.First().TotalCapacity;
            Assert.Equal(firstDayTotalCapacityForEquipment2, day1CapacityFilteredByEquipment2);
            foreach (var reservationEvent in reservationEventsHavingNetReservedDemand)
            {
                var reservedDemand = capacityOutlookData.CapacityOutlookOverTime.Where(x => x.Date == reservationEvent.Date).First().ReservedDemand;
                Assert.Equal(reservationEvent.NetReservedDemand, reservedDemand);
            }
        }

        [Fact]
        public async Task GetCapacityOutLookOverTimeAsync_ShouldShowUnavailableCapacity_onHoliday()
        {
            var equip1HolidayAfterToday = 5;
            var equip2HolidayAfterToday = 7;

            _tenantRepository
                .Setup(_ => _.GetTenantCurrentTimeAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(DateTime.Today);

            _ticketTaskRepository
               .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
               .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetDailyEquipmentCapacityOutlookAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(MockedCapacityOutlook.GetDailyEquipmentCapacityOutlook(equip1HolidayAfterToday, equip2HolidayAfterToday).Where(x => x.EquipmentId == "equip2").ToList());

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var capacityOutlookData = await leadTimeProvider.GetCapacityOutlookOverTimeAsync(new DashboardFilter()
            {
                StartDate = DateTime.Today,
                EndDate = DateTime.Today.AddDays(12),
                Equipments = new List<string> { "equip2" }
            }, CancellationToken.None);

            Assert.NotNull(capacityOutlookData);
            Assert.Equal(24, capacityOutlookData.CapacityOutlookOverTime[equip2HolidayAfterToday].HolidayHours);
            Assert.Equal(0, capacityOutlookData.CapacityOutlookOverTime[equip2HolidayAfterToday].TotalCapacity);
            Assert.Equal(24, capacityOutlookData.CapacityOutlookOverTime[equip2HolidayAfterToday].UnstaffedHours);

        }

        [Fact]
        public async Task GetCapacityOutLookOverTimeAsync_ShouldCalculate_DowntimeHours()
        {
            _tenantRepository
                .Setup(_ => _.GetTenantCurrentTimeAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(DateTime.Today);

            _ticketTaskRepository
               .Setup(_ => _.GetTicketsDemandAsync(It.IsAny<DashboardFilter>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
               .ReturnsAsync(GetTicketsDemands());

            _equipmentRepository
                .Setup(_ => _.GetDailyEquipmentCapacityOutlookAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(MockedCapacityOutlook.GetDailyEquipmentCapacityOutlookWithDowntime());

            _equipmentRepository
                .Setup(_ => _.GetAllEquipmentsDataAsync(It.IsAny<DashboardFilter>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(GetAllEquipmentDetailsData());

            _reservationRepository
                .Setup(_ => _.GetReservationEventAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<ReservationEventDto>());

            var leadTimeProvider = new LeadTimeReportProvider(_equipmentRepository.Object, _cachedEquipmentRepository.Object, _ticketTaskRepository.Object, _facilityRepository.Object, _tenantRepository.Object, _reservationRepository.Object, _configurableViewsProvider.Object);
            var capacityOutlookData = await leadTimeProvider.GetCapacityOutlookOverTimeAsync(new DashboardFilter()
            {
                StartDate = DateTime.Today,
                EndDate = DateTime.Today.AddDays(12),
                Equipments = new List<string> { "equip2" }
            }, CancellationToken.None);

            Assert.NotNull(capacityOutlookData);
            Assert.Equal(7, capacityOutlookData.CapacityOutlookOverTime[2].DowntimeHours);
            Assert.Equal(6, capacityOutlookData.CapacityOutlookOverTime[3].DowntimeHours);

        }


        private static List<TicketsDemand> GetTicketsDemands()
        {
            return new List<TicketsDemand>
            {
                new TicketsDemand{ TicketId = "ticket1", EquipmentId = "equip1", EquipmentName ="1",
                    FacilityId="facility1", FacilityName="DemoFacility",
                    WorkcenterId ="wc1", WorkcenterName = "Digital HP", ValueStreamId = "vs1", ValueStreamName ="EquipVS",
                    EstTotalHours = 10f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 24), SourceTicketId ="5111", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket2", EquipmentId = "equip1", EquipmentName ="1",
                    FacilityId="facility1", FacilityName="DemoFacility",
                    WorkcenterId ="wc1", WorkcenterName = "Digital HP", ValueStreamId = "vs1", ValueStreamName ="EquipVS",
                    EstTotalHours = 5f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 26), SourceTicketId ="5112", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket2", EquipmentId = "equip2", EquipmentName ="2",
                    FacilityId="facility1", FacilityName="DemoFacility",
                    WorkcenterId ="wc1", WorkcenterName = "Digital HP", ValueStreamId = "vs1", ValueStreamName ="EquipVS",
                    EstTotalHours = 7.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 26), SourceTicketId ="5112", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket3", EquipmentId = "equip2", EquipmentName ="2",
                    FacilityId="facility1", FacilityName="DemoFacility",
                    WorkcenterId ="wc1", WorkcenterName = "Digital HP", ValueStreamId = "vs1", ValueStreamName ="EquipVS",
                    EstTotalHours = 2.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 27), SourceTicketId ="5113", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket4", EquipmentId = "equip3", EquipmentName ="3",
                    FacilityId="facility1", FacilityName="DemoFacility",
                    WorkcenterId ="wc1", WorkcenterName = "Digital HP", ValueStreamId = "vs2", ValueStreamName ="PressVS",
                    EstTotalHours = 4.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 28), SourceTicketId ="5114", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket5", EquipmentId = "equip4", EquipmentName ="4",
                    FacilityId="facility1", FacilityName="DemoFacility",
                    WorkcenterId ="wc2", WorkcenterName = "Rewinder", ValueStreamId = "vs2", ValueStreamName ="PressVS",
                    EstTotalHours = 2.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 29), SourceTicketId ="5115", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket6", EquipmentId = "equip5", EquipmentName ="3",
                    FacilityId="facility2", FacilityName="DemoFacility2",
                    WorkcenterId ="wc3", WorkcenterName = "Digicon Finishing", ValueStreamId = "vs2", ValueStreamName ="PressVS",
                    EstTotalHours = 4.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 28), SourceTicketId ="5114", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket6", EquipmentId = "equip6", EquipmentName ="4",
                    FacilityId="facility2", FacilityName="DemoFacility2",
                    WorkcenterId ="wc3", WorkcenterName = "Digicon Finishing", ValueStreamId = "vs2", ValueStreamName ="PressVS",
                    EstTotalHours = 2.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 29), SourceTicketId ="5115", UnplannedAllowance = 10 },

                new TicketsDemand{ TicketId = "ticket6", EquipmentId = "equip6", EquipmentName ="4",
                    FacilityId="facility2", FacilityName="DemoFacility2",
                    WorkcenterId ="wc3", WorkcenterName = "Digicon Finishing", ValueStreamId = "vs3", ValueStreamName ="PressVS-3",
                    EstTotalHours = 2.7f, MinLeadTime = 11, ShipByDate = new DateTime(2024,1, 29), SourceTicketId ="5115", UnplannedAllowance = 10 }
            };
        }

        private static List<DailyEquipmentCapacity> GetDailyEquipmentCapacities()
        {
            var result = new List<DailyEquipmentCapacity>();
            var startDate = new DateTime(2024, 4, 10);
            for (int i = 0; i < 180; i++)
            {
                if (startDate.AddDays(i).DayOfWeek != DayOfWeek.Saturday &&
                    startDate.AddDays(i).DayOfWeek != DayOfWeek.Sunday)
                {
                    result.Add(new DailyEquipmentCapacity
                    {
                        EquipmentId = "equip1",
                        WorkcenterId = "wc1",
                        ActualCapacityHours = 7.2f,
                        TotalCapacityHours = 8f,
                        TheDate = startDate.AddDays(i),
                        DemandHours = 0,
                        AvailabilityThreshold = 0,
                        InternalLeadTime = 10,
                        UnplannedAllowance = 10,
                        UnplannedAllowanceHours = 0.8f,
                    });
                    result.Add(new DailyEquipmentCapacity
                    {
                        EquipmentId = "equip2",
                        WorkcenterId = "wc1",
                        ActualCapacityHours = 3.6f,
                        TotalCapacityHours = 4f,
                        TheDate = startDate.AddDays(i),
                        DemandHours = 0,
                        AvailabilityThreshold = 0,
                        InternalLeadTime = 11,
                        UnplannedAllowance = 10,
                        UnplannedAllowanceHours = 0.4f,
                    });
                    result.Add(new DailyEquipmentCapacity
                    {
                        EquipmentId = "equip3",
                        WorkcenterId = "wc1",
                        ActualCapacityHours = 7.2f,
                        TotalCapacityHours = 8f,
                        TheDate = startDate.AddDays(i),
                        DemandHours = 0,
                        AvailabilityThreshold = 0,
                        InternalLeadTime = 14,
                        UnplannedAllowance = 10,
                        UnplannedAllowanceHours = 0.8f,
                    });
                    result.Add(new DailyEquipmentCapacity
                    {
                        EquipmentId = "equip4",
                        WorkcenterId = "wc2",
                        ActualCapacityHours = 7.2f,
                        TotalCapacityHours = 8f,
                        TheDate = startDate.AddDays(i),
                        DemandHours = 0,
                        AvailabilityThreshold = 0,
                        InternalLeadTime = 12,
                        UnplannedAllowance = 10,
                        UnplannedAllowanceHours = 0.8f,
                    });
                }
            }
            return result;
        }

        //public static List<OpenTicketDetailsDto> GetOpoenTicketDetailsDtos()
        //{
        //    var result = new List<OpenTicketDetailsDto>();
        //    result.Add(new OpenTicketDetailsDto()
        //    {
        //        TicketId = "ticket1",
        //        TicketNumber = "11111",
        //        CustomerName = "c1",
        //        GeneralDescription = "d1",
        //        TaskName = "Press",
        //        WorkcenterName = "w1",
        //        IsComplete = false,
        //        EstimatedLength = 10,
        //        EstimatedQuantity = 1000,
        //        EstimatedTotalHours = 0.25f,
        //        ScheduledHours = 0.25f,
        //        EstMaxDueDateTime = DateTime.Today.AddDays(2),
        //        ShipByDate = DateTime.Today.AddDays(5),
        //        ScheduledEquipment = "1A",
        //        ScheduledEquipmentId = "e1",
        //        IsScheduled = true,
        //        IsTicketGeneralNotePresent = false,
        //        PlannedEquipment = "1A",
        //        PlannedEquipmentId = "e1",
        //        ScheduledTaskEndsAt = DateTime.Today.AddDays(1),
        //    });
        //    result.Add(new OpenTicketDetailsDto()
        //    {
        //        TicketId = "ticket1",
        //        TicketNumber = "11111",
        //        CustomerName = "c1",
        //        GeneralDescription = "d1",
        //        TaskName = "Equip",
        //        WorkcenterName = "w1",
        //        IsComplete = false,
        //        EstimatedLength = 20,
        //        EstimatedQuantity = 1000,
        //        EstimatedTotalHours = 0.25f,
        //        ScheduledHours = 0.25f,
        //        EstMaxDueDateTime = DateTime.Today.AddDays(3),
        //        ShipByDate = DateTime.Today.AddDays(5),
        //        ScheduledEquipment = "1A",
        //        ScheduledEquipmentId = "e1",
        //        IsScheduled = true,
        //        IsTicketGeneralNotePresent = false,
        //        PlannedEquipment = "1A",
        //        PlannedEquipmentId = "e1",
        //        ScheduledTaskEndsAt = DateTime.Today.AddDays(2),
        //    });
        //    result.Add(new OpenTicketDetailsDto()
        //    {
        //        TicketId = "ticket2",
        //        TicketNumber = "11112",
        //        CustomerName = "c2",
        //        GeneralDescription = "d2",
        //        TaskName = "Equip",
        //        WorkcenterName = "w1",
        //        IsComplete = false,
        //        EstimatedLength = 20,
        //        EstimatedQuantity = 1000,
        //        IsOnPress = false,
        //        EstimatedTotalHours = 0.25f,
        //        ScheduledHours = 0.25f,
        //        EstMaxDueDateTime = DateTime.Today.AddDays(5),
        //        ShipByDate = DateTime.Today.AddDays(2),
        //        ScheduledEquipment = "1A",
        //        ScheduledEquipmentId = "e1",
        //        IsScheduled = true,
        //        IsTicketGeneralNotePresent = false,
        //        PlannedEquipment = "1A",
        //        PlannedEquipmentId = "e1",
        //        ScheduledTaskEndsAt = DateTime.Today.AddDays(6),
        //    });
        //    return result;
        //}

        public static List<LastRunInfo> GetLastRunInfos()
        {
            return new List<LastRunInfo>()
            {
                new LastRunInfo()
                {
                    LastRunEquipmentId = "equip1",
                    SourceTicketId = "ticket1"
                }
            };
        }

        public static List<EquipemntDetailsData> GetAllEquipmentDetailsData()
        {
            return new List<EquipemntDetailsData> {
                new EquipemntDetailsData(){ EquipmentId = "equip1",FacilityId="facility1", FacilityName="DemoFacility", EquipmentName = "1", WorkcenterId ="wc1", WorkcenterName = "Digital HP",ValueStreams = new List<ValueStreamDto> {new ValueStreamDto(){Id = "vs1", Name ="EquipVS"} } },
                new EquipemntDetailsData(){ EquipmentId = "equip2",FacilityId="facility1", FacilityName="DemoFacility", EquipmentName = "2", WorkcenterId ="wc1", WorkcenterName = "Digital HP",ValueStreams = new List<ValueStreamDto> {new ValueStreamDto(){Id = "vs1", Name ="EquipVS"} }  },
                new EquipemntDetailsData(){ EquipmentId = "equip3",FacilityId="facility1", FacilityName="DemoFacility", EquipmentName = "3", WorkcenterId ="wc1", WorkcenterName = "Digital HP",ValueStreams = new List<ValueStreamDto> {new ValueStreamDto(){Id = "vs2", Name = "PressVS" } } },
                new EquipemntDetailsData(){ EquipmentId = "equip4",FacilityId="facility1", FacilityName="DemoFacility", EquipmentName = "4", WorkcenterId ="wc2", WorkcenterName = "Rewinder", ValueStreams = new List<ValueStreamDto> {new ValueStreamDto(){Id = "vs2", Name = "PressVS" } } },
                new EquipemntDetailsData(){ EquipmentId = "equip5",FacilityId="facility2", FacilityName="DemoFacility2", EquipmentName = "5", WorkcenterId ="wc3", WorkcenterName = "Digicon Finishing",ValueStreams = new List<ValueStreamDto> {new ValueStreamDto(){Id = "vs2", Name = "PressVS" } }  },
                new EquipemntDetailsData(){ EquipmentId = "equip6",FacilityId="facility2", FacilityName="DemoFacility2", EquipmentName = "6", WorkcenterId ="wc3", WorkcenterName = "Digicon Finishing",ValueStreams = new List<ValueStreamDto> {new ValueStreamDto(){Id = "vs2", Name = "PressVS" }, new ValueStreamDto() { Id = "vs3", Name = "PressVS-3" } } },

            };
        }

        public static List<ReservationEventDto> GetReservationEvents(DateTime startDate)
        {
            return new List<ReservationEventDto>
            {
                new ReservationEventDto { Id = "event1", ActualDemand = 10, NetReservedDemand = 0,  Date = startDate.AddDays(1), EquipmentId = "equip1", WorkcenterId = "wc1", ReservationId = "reservation1" },
                new ReservationEventDto { Id = "event2", ActualDemand = 10, NetReservedDemand = 0,  Date = startDate.AddDays(5), EquipmentId = "equip1", WorkcenterId = "wc1", ReservationId = "reservation1" },
                new ReservationEventDto { Id = "event3", ActualDemand = 2, NetReservedDemand = 6, Date = startDate.AddDays(9), EquipmentId = "equip1", WorkcenterId = "wc1", ReservationId = "reservation1" },
                new ReservationEventDto { Id = "event4", ActualDemand = 1, NetReservedDemand = 7, Date = startDate.AddDays(13), EquipmentId = "equip1", WorkcenterId = "wc1", ReservationId = "reservation1" },
                new ReservationEventDto { Id = "event5", ActualDemand = 0, NetReservedDemand = 8, Date = startDate.AddDays(18), EquipmentId = "equip1", WorkcenterId = "wc1", ReservationId = "reservation1" },
                new ReservationEventDto { Id = "event6", ActualDemand = 0, NetReservedDemand = 8, Date = startDate.AddDays(23), EquipmentId = "equip1", WorkcenterId = "wc1", ReservationId = "reservation1" },
            };
        }

    }
}


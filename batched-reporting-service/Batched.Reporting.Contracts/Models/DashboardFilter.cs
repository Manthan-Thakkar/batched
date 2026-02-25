namespace Batched.Reporting.Contracts
{
    public class DashboardFilter
    {
        public DashboardFilter()
        {
            Facilities = new List<string>();
            ValueStreams = new List<string>();
            Workcenters = new List<string>();
            Equipments = new List<string>();
            Tickets = new List<string>();
            ScheduleStatus = "";
        }

        public List<string> Facilities { get; set; }
        public List<string> ValueStreams { get; set; }
        public List<string> Workcenters { get; set; }
        public List<string> Equipments { get; set; }
        public List<string> Tickets { get; set; } 
        public string ScheduleStatus { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
